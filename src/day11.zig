const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const Array = std.ArrayList;

pub fn day(writer: anytype, alloc: Allocator) !void {
    _ = alloc;
    _ = writer;
}

/// expand and then do path finding between #'s using only LRUD
const Galaxy = struct {
    id: i32,
    x: i32,
    y: i32,
};
const Distance = struct {
    g1: *Galaxy,
    g2: *Galaxy,
    distance: i32 = 0,
    pub fn findDistance(self: *Distance) i32 {
        return self.g2.x - self.g1.x +
            self.g2.y - self.g1.y;
    }
};
const Map = struct {
    width: i32,
    height: i32,
    data: Array(Array(u8)),
    galaxies: Array(Galaxy),
    distances: Array(Distance),

    var ally: Allocator = undefined;

    pub fn init(input: []const u8, alloc: Allocator) !Map {
        const w: i32 = @intCast(std.mem.indexOf(u8, input, "\n").?);
        const newLines = std.mem.count(u8, input, "\n");

        const h: i32 = @divExact(@as(i32, @intCast(input.len - newLines)), w);
        ally = alloc;

        var m = Map{
            .width = w,
            .height = h,
            .data = Array(Array(u8)).init(ally),
            .galaxies = Array(Galaxy).init(ally),
            .distances = Array(Distance).init(ally),
        };

        for (0..@intCast(w)) |_|
            try m.data.append(Array(u8).init(ally));

        try m.parse(input);
        return m;
    }
    pub fn deinit(self: *Map) void {
        for (self.data.items) |*col|
            col.deinit();

        self.data.deinit();
    }

    fn parse(self: *Map, input: []const u8) !void {
        var rows = std.mem.split(u8, input, "\n");
        var rowIdx: usize = 0;

        while (rows.next()) |row| {
            for (row) |col| {
                try self.data.items[rowIdx].append(col);
            }
            rowIdx += 1;
        }
    }

    pub fn getDistances(self: *Map) u32 {
        var sum: u32 = 0;
        for (self.distances.items) |*d| {
            std.debug.print("Distance between {} and {} = {}\n", .{ d.g1.id, d.g2.id, @abs(d.findDistance()) });
            sum += @abs(d.findDistance());
        }
        return sum;
    }

    fn findGalaxies(self: *Map) !void {
        var ids: i32 = 0;
        for (self.data.items, 0..) |row, x| {
            for (row.items, 0..) |col, y| {
                if (col == '#') {
                    try self.galaxies.append(Galaxy{
                        .id = ids,
                        .x = @intCast(x),
                        .y = @intCast(y),
                    });
                    ids += 1;
                }
            }
        }
        for (self.galaxies.items, 0..) |*g, i| {
            for (self.galaxies.items[i + 1 ..]) |*other| {
                try self.distances.append(Distance{
                    .g1 = g,
                    .g2 = other,
                });
            }
        }
    }

    fn expand(self: *Map) !void {
        //expand by rows

        var columnsToExpand = try ally.alloc(bool, @intCast(self.width));
        var rowsToExpand = try ally.alloc(bool, @intCast(self.height));
        @memset(columnsToExpand, true);
        @memset(rowsToExpand, true);

        for (self.data.items, 0..) |row, i| {
            var gCount: usize = 0;
            for (row.items, 0..) |col, j| {
                if (col == '#') {
                    gCount += 1;
                    columnsToExpand[j] = false;
                }
            }
            if (gCount != 0) {
                rowsToExpand[i] = false;
            }
        }

        var addedRows: usize = 0;
        var rowExp = std.mem.indexOfPos(bool, rowsToExpand, 0, &[_]bool{true});
        while (rowExp) |r| {
            var a = Array(u8).init(ally);
            try a.appendNTimes('.', @intCast(self.width));
            try self.data.insert(r + addedRows, a);
            rowExp = std.mem.indexOfPos(bool, rowsToExpand, r + 1, &[_]bool{true});
            self.height += 1;
            addedRows += 1;
        }

        var addedCols: usize = 0;
        var colExp = std.mem.indexOfPos(bool, columnsToExpand, 0, &[_]bool{true});
        while (colExp) |c| {
            for (self.data.items) |*row| {
                try row.insert(c + addedCols, '.');
            }
            colExp = std.mem.indexOfPos(bool, columnsToExpand, c + 1, &[_]bool{true});
            self.width += 1;
            addedCols += 1;
        }
    }

    pub fn format(self: Map, fmt: []const u8, options: anytype, writer: anytype) !void {
        _ = options;
        _ = fmt;

        // try writer.writeAll("Map\n");
        for (self.data.items, 0..) |*col, i| {
            for (col.items) |row| {
                try writer.print("{c}", .{row});
            }
            if (i < @as(usize, @intCast(self.height - 1))) try writer.writeAll("\n");
        }
    }
};

test "map" {
    var a = std.heap.ArenaAllocator.init(testing.allocator);
    defer a.deinit();

    const alloc = a.allocator();

    var m = try Map.init(Sample1, alloc);
    defer m.deinit();

    const buf = try alloc.alloc(u8, 1000);
    var string = try std.fmt.bufPrint(buf, "{}", .{m});
    try testing.expectEqualDeep(string, @constCast(Sample1));

    try m.expand();
    string = try std.fmt.bufPrint(buf, "{}", .{m});
    try testing.expectEqualDeep(string, @constCast(Sample1Expanded));

    try m.findGalaxies();
    try testing.expectEqual(m.galaxies.items.len, 9);

    std.debug.print("{}\n", .{m.getDistances()});
    try testing.expectEqual(m.getDistances(), 374);
}
const Sample1 =
    \\...#......
    \\.......#..
    \\#.........
    \\..........
    \\......#...
    \\.#........
    \\.........#
    \\..........
    \\.......#..
    \\#...#.....
;

const Sample1Expanded =
    \\....#........
    \\.........#...
    \\#............
    \\.............
    \\.............
    \\........#....
    \\.#...........
    \\............#
    \\.............
    \\.............
    \\.........#...
    \\#....#.......
;
