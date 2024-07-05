const std = @import("std");
const atoi = @import("root.zig").atoi2;
pub const Allocator = std.mem.Allocator;
pub const testing = std.testing;
pub const Array = std.ArrayList;

pub fn day(writer: anytype, alloc: Allocator) !void {
    _ = writer; // autofix
    _ = alloc; // autofix
}

fn part1(input: []const u8, alloc: Allocator) !u32 {
    _ = input; // autofix
    _ = alloc;

    const sum: u32 = 0;

    return sum;
}

fn part2(input: []const u8, alloc: Allocator) !u32 {
    _ = input; // autofix
    _ = alloc; // autofix

}

const Cell = enum(u8) {
    Start = 'S',
    End = 'E',
    Path = '.',
    Forest = '#',
    Slope_down = 'v',
    Slope_right = '>',
    Slope_left = '<',
    Slope_up = '^',
    FoundPath = '*',
};

const Coord = struct {
    x: usize = 0,
    y: usize = 0,

    pub fn format(self: Coord, comptime fmt: []const u8, options: anytype, writer: anytype) !void {
        _ = fmt; // autofix
        _ = options; // autofix
        try writer.print("({},{})", .{ self.x, self.y });
    }
};

const Maze = struct {
    cells: std.AutoArrayHashMap(Coord, Cell),
    width: usize = 0,
    height: usize = 0,
    start: Coord = Coord{},
    end: Coord = Coord{},

    var alloc: std.mem.Allocator = undefined;

    pub fn init(allocator: std.mem.Allocator, input: []u8) !Maze {
        alloc = allocator;
        var c = std.AutoArrayHashMap(Coord, Cell).init(alloc);
        errdefer c.deinit();
        var lines = std.mem.splitScalar(u8, input, '\n');
        var m = Maze{
            .cells = c,
        };
        while (lines.next()) |_| m.height += 1;
        lines.reset();

        var y: usize = 0;

        while (lines.next()) |line| {
            for (line, 0..) |char, x| {
                const coord = Coord{ .x = x, .y = y };
                const cell = switch (char) {
                    '.' => blk: {
                        if (y == 0) {
                            m.start = coord;
                            break :blk Cell.Start;
                        } else {
                            if (y == m.height - 1) {
                                m.end = coord;
                                break :blk Cell.End;
                            } else break :blk Cell.Path;
                        }
                    },
                    '#' => Cell.Forest,
                    'v' => Cell.Slope_down,
                    '>' => Cell.Slope_right,
                    '<' => Cell.Slope_left,
                    '^' => Cell.Slope_up,
                    else => return error.Unreachable,
                };
                try c.put(coord, cell);
                m.width = x + 1;
            }
            y += 1;
        }
        m.cells = c;
        return m;
    }
    pub fn deinit(self: *Maze) void {
        self.cells.deinit();
    }

    pub fn print(self: *Maze) void {
        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const coord = Coord{ .x = x, .y = y };
                if (self.cells.get(coord)) |cell| {
                    std.debug.print("{c}", .{@intFromEnum(cell)});
                } else {
                    std.debug.print(" ", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn printWithPath(self: *Maze, path: []Coord) !void {
        var c = try self.cells.clone();
        defer c.deinit();
        for (path) |coord| {
            if (c.getEntry(coord)) |e| {
                e.value_ptr.* = Cell.FoundPath;
                std.debug.print("{},{}\n", .{ coord.x, coord.y });
            }
        }

        for (0..self.height) |y| {
            for (0..self.width) |x| {
                const coord = Coord{ .x = x, .y = y };
                if (c.get(coord)) |cell| {
                    std.debug.print("{c}", .{@intFromEnum(cell)});
                } else {
                    std.debug.print(" ", .{});
                }
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn findNeighbors(self: *Maze, allocator: std.mem.Allocator, coord: Coord) !std.ArrayList(Coord) {
        var neighbors = std.ArrayList(Coord).init(allocator);
        const x = coord.x;
        const y = coord.y;
        if (x > 0) try neighbors.append(Coord{ .x = x - 1, .y = y });
        if (x < self.width) try neighbors.append(Coord{ .x = x + 1, .y = y });
        if (y > 0) try neighbors.append(Coord{ .x = x, .y = y - 1 });
        if (y < self.height) try neighbors.append(Coord{ .x = x, .y = y + 1 });
        return neighbors;
    }

    pub fn dfs(self: *Maze) !std.ArrayList(Coord) {
        var stack = std.ArrayList(Coord).init(alloc);
        try stack.append(self.start);
        var visited = std.AutoArrayHashMap(Coord, bool).init(alloc);
        defer visited.deinit();
        wl: while (stack.items.len > 0) {
            const current = stack.getLast();
            if (current.x == self.end.x and current.y == self.end.y) return stack;
            if (visited.contains(current)) continue :wl;
            try visited.put(current, true);
            var neighbors = try self.findNeighbors(alloc, current);
            defer neighbors.deinit();
            blk: for (neighbors.items) |n| {
                if (visited.contains(n)) continue :blk;
                if (self.cells.get(n)) |cell| {
                    std.debug.print("Checking: {c} @ {}\n", .{ @intFromEnum(cell), n });
                    switch (cell) {
                        .Forest, .Slope_up, .Slope_left => continue :blk,
                        else => {
                            std.debug.print("Found: {c} @ {}\n", .{ @intFromEnum(cell), n });
                            try stack.append(n);
                        },
                    }
                }
            }
        }
        return error.Unreachable;
    }
};

test "day 1" {
    var m = try Maze.init(testing.allocator, @constCast(test1Input));
    defer m.deinit();

    std.debug.print("Start: ({},{}), End: ({},{})\n", .{
        m.start.x,
        m.start.y,
        m.end.x,
        m.end.y,
    });

    // for (m.cells.values()) |cell| {
    //     std.debug.print("{s}\n", .{@tagName(cell)});
    // }
    var neighbors = try m.findNeighbors(std.testing.allocator, Coord{ .x = 0, .y = 0 });
    defer neighbors.deinit();
    for (neighbors.items) |n| {
        std.debug.print("({}, {})\n", .{ n.x, n.y });
    }

    var path = try m.dfs();
    defer path.deinit();

    std.debug.print("Path Len: {}\n", .{path.items.len});
    try m.printWithPath(path.items);
    try testing.expectEqual(path.items.len, 94);
}

const test1Answer = 94;
const test1Input =
    \\#.#####################
    \\#.......#########...###
    \\#######.#########.#.###
    \\###.....#.>.>.###.#.###
    \\###v#####.#v#.###.#.###
    \\###.>...#.#.#.....#...#
    \\###v###.#.#.#########.#
    \\###...#.#.#.......#...#
    \\#####.#.#.#######.#.###
    \\#.....#.#.#.......#...#
    \\#.#####.#.#.#########v#
    \\#.#...#...#...###...>.#
    \\#.#.#v#######v###.###v#
    \\#...#.>.#...>.>.#.###.#
    \\#####v#.#.###v#.#.###.#
    \\#.....#...#...#.#.#...#
    \\#.#########.###.#.#.###
    \\#...###...#...#...#.###
    \\###.###.#.###v#####v###
    \\#...#...#.#.>.>.#.>.###
    \\#.###.###.#.###.#.#v###
    \\#.....###...###...#...#
    \\#####################.#
;

const day1Input =
    \\#.###########################################################################################################################################
    \\#.#...#...#...#...#...#.........#.......#...#.......#...###...###...#...#...#...###...#...#...#...#.....###...#...###...#.....#...#...#...###
    \\#.#.#.#.#.#.#.#.#.#.#.#.#######.#.#####.#.#.#.#####.#.#.###.#.###.#.#.#.#.#.#.#.###.#.#.#.#.#.#.#.#.###.###.#.#.#.###.#.#.###.#.#.#.#.#.#.###
    \\#.#.#.#.#.#.#.#.#.#.#...#.......#.....#.#.#.#.....#...#...#.#.#...#.#.#...#.#.#...#.#.#.#.#.#.#.#.#.#...#...#.#.#...#.#.#...#.#.#...#...#...#
    \\#.#.#.#.#v#.#.#.#.#.#####.###########.#.#.#.#####.#######.#.#.#.###.#.#####.#.###.#.#.#.#.#.#.#.#.#.#.###.###.#.###.#.#.###.#.#.###########.#
    \\#...#...#.>.#...#...#.....#...#...#...#...#...#...#.......#.#...#...#.#.....#...#.#.#...#.#.#.#.#...#...#...#.#.#...#.#.###.#.#.#...........#
    \\#########v###########.#####.#.#.#.#.#########.#.###.#######.#####.###.#.#######.#.#.#####.#.#.#.#######.###.#.#.#.###.#.###.#.#.#.###########
    \\#...#...#.#...........#...#.#.#.#.#.......#...#...#.#...###.#.....###.#.#...###.#.#.....#.#.#.#.#.......#...#...#...#.#...#.#.#.#.#...#...###
    \\#.#.#.#.#.#.###########.#.#.#.#.#.#######.#.#####.#.#.#.###.#.#######.#.#.#.###.#.#####.#.#.#.#.#.#######.#########.#.###.#.#.#.#.#.#.#.#.###
    \\#.#...#...#...#...###...#...#.#.#.###...#.#.#...#.#.#.#.#...#...>.>.#.#.#.#.#...#.#...#.#.#.#.#.#.#...###.....#####.#.#...#.#.#.#...#...#...#
    \\#.###########.#.#.###.#######.#.#.###.#.#.#.#.#.#.#.#.#.#.#######v#.#.#.#.#.#.###.#.#.#.#.#.#.#.#.#.#.#######.#####.#.#.###.#.#.###########.#
    \\#.........###.#.#...#...#.....#.#.....#.#.#...#.#.#.#.#.#...#.....#...#.#.#.#...#.#.#.#.#.#.#.#.#.#.#.>.>...#.....#...#.....#...#...#.......#
    \\#########.###.#.###.###.#.#####.#######.#.#####.#.#.#.#.###.#.#########.#.#.###.#.#.#.#.#.#.#.#.#.#.###v###.#####.###############.#.#.#######
    \\#####...#.#...#...#...#.#.#...#.......#.#.....#.#.#...#.#...#.#...###...#.#.#...#...#.#.#.#.#...#.#...#...#...#...###...#...###...#.#.......#
    \\#####.#.#.#.#####.###.#.#.#.#.#######.#.#####.#.#.#####.#.###.#.#.###.###.#.#.#######.#.#.#.#####.###.###.###.#.#####.#.#.#.###.###.#######.#
    \\#.....#...#.......###.#.#...#.#.>.>...#.......#...#...#.#...#...#...#.....#.#.#...###...#.#.#.....#...###...#...#.....#...#.....###...#.....#
    \\#.###################.#.#####.#.#v#################.#.#.###.#######.#######.#.#.#.#######.#.#.#####.#######.#####.###################.#.#####
    \\#...........#.........#.#.....#.#...#...###...###...#.#.#...###...#.....#...#...#.......#.#.#.#...#.#.....#.....#...#.............#...#.....#
    \\###########.#.#########.#.#####.###.#.#.###.#.###.###.#.#.#####.#.#####.#.#############.#.#.#.#.#.#.#.###.#####.###.#.###########.#.#######.#
    \\#...........#.....#...#.#.#...#.#...#.#.....#.....#...#.#.#...#.#.......#.>.>.....#.....#.#.#.#.#...#.#...#...#...#.#.#...........#...#.....#
    \\#.###############.#.#.#.#.#.#.#.#.###.#############.###.#.#.#.#.###########v#####.#.#####.#.#.#.#####.#.###.#.###.#.#.#.#############.#.#####
    \\#.........#.....#.#.#.#.#...#...#.....#.....#.....#...#...#.#...#...###...#.....#.#.....#...#...#...#.#.#...#.....#...#.............#.#.....#
    \\#########.#.###.#.#.#.#.###############.###.#.###.###.#####.#####.#.###.#.#####.#.#####.#########.#.#.#.#.#########################.#.#####.#
    \\#.........#.#...#...#...###.....#...###...#.#...#.....#.....#...#.#.....#.#.....#...#...#...###...#...#.#.........#...###...........#...#...#
    \\#.#########.#.#############.###.#.#.#####.#.###.#######.#####.#.#.#######.#.#######.#.###.#.###.#######.#########.#.#.###.#############.#.###
    \\#.......#...#.#...#.....#...#...#.#.#...#.#.....#...###.......#...#.......#.......#...#...#...#.......#.........#...#.#...#...........#.#...#
    \\#######.#.###.#.#.#.###.#.###.###.#.#.#.#.#######.#.###############.#############.#####.#####.#######.#########.#####.#.###.#########.#.###.#
    \\#.......#...#.#.#.#...#.#...#.###.#.#.#.#.###...#.#.....###...#.....#...###.......#...#...#...#...###.#.......#.#.....#.....#.........#.....#
    \\#.#########.#.#.#.###.#.###.#.###.#.#.#.#v###.#.#.#####.###.#.#.#####.#.###.#######.#.###.#.###.#.###.#.#####.#.#.###########v###############
    \\#.........#.#.#.#.#...#...#.#...#.#.#.#.>.>...#.#.#.....#...#.#.......#.#...#...###.#...#.#...#.#...#...#.....#...#...#...#.>.#...#...#...###
    \\#########.#.#.#.#.#.#####.#.###.#.#.#.###v#####.#.#.#####.###.#########.#.###.#.###.###.#.###.#.###.#####.#########.#.#.#.#.#v#.#.#.#.#.#.###
    \\#.........#.#...#.#...###.#.###.#.#...#...###...#.#.#...#...#.#...#.....#...#.#.###.#...#...#.#.#...#...#...###...#.#.#.#.#.#...#.#.#...#...#
    \\#.#########.#####.###.###.#.###.#.#####.#####.###.#.#.#.###.#.#.#.#v#######v#.#.###.#.#####.#.#.#.###.#.###v###.#.#.#.#.#.#.#####.#.#######.#
    \\#.#...#...#.#...#.#...#...#.#...#.#...#.....#.....#.#.#...#.#.#.#.>.>...#.>.>.#...#.#.#...#.#.#.#.#...#...>.>...#.#.#.#.#...###...#.#.......#
    \\#.#.#v#.#.#.#.#.#.#.###.###.#.###.#.#.#####.#######.#.###.#.#.#.###v###.#.#v#####.#.#.#.#.#.#.#.#.#.#######v#####.#.#.#.#######.###.#.#######
    \\#.#.#.>.#.#...#.#...#...#...#.....#.#.#...#.......#.#...#.#.#.#.#...#...#.#.#...#.#.#.#.#.#.#.#.#.#.#.....#.....#...#.#.###...#...#.#.#...###
    \\#.#.#v###.#####.#####.###.#########.#.#.#.#######.#.###.#.#.#.#.#.###.###.#.#.#.#.#.#.#.#.#.#.#.#.#.#.###.#####.#####.#.###.#.###.#.#.#.#.###
    \\#...#...#.......#...#...#...#.......#...#.....#...#.....#...#...#...#.....#...#.#.#.#.#.#...#.#.#.#.#...#.....#.#.....#...#.#.....#.#...#...#
    \\#######.#########.#.###.###.#.###############.#.###################.###########.#.#.#.#.#####.#.#.#.###.#####.#.#.#######.#.#######.#######.#
    \\#.......#.........#...#.#...#.............#...#...#.....###...#...#...#.........#...#...#.....#.#...###.....#.#.#.....#...#.#.......#.....#.#
    \\#.#######.###########.#.#.###############.#.#####.#.###.###.#.#.#.###.#.#################.#####.###########.#.#.#####.#.###.#.#######.###.#.#
    \\#.......#.#.....#.....#...#...#...#.....#.#.......#...#.###.#.#.#...#.#...#...#...#...###.....#.#...........#.#.....#.#.#...#.#.....#...#.#.#
    \\#######.#.#.###.#.#########.#.#.#.#.###.#.###########.#.###.#.#.###.#.###.#.#.#.#.#.#.#######.#.#.###########.#####.#.#.#.###.#.###.###.#.#.#
    \\#.......#.#...#.#.#.....#...#...#...###...#...#.......#.....#.#...#...###...#...#...#.......#...#...........#.......#...#.....#...#.#...#.#.#
    \\#.#######.###.#.#.#.###.#.#################.#.#.#############.###.#########################.###############.#####################.#.#.###.#.#
    \\#...#.....#...#...#.#...#...................#.#.............#...#.#...###...#...............#...#...........###...###...#.........#...#...#.#
    \\###.#.#####.#######.#.#######################.#############.###.#.#.#.###.#.#.###############.#.#.#############.#.###.#.#.#############.###.#
    \\###...#...#.....###.#.#...#...#...........#...#.............###.#...#...#.#...#.....#.........#.#...............#.#...#.#.......#...###.....#
    \\#######.#.#####.###.#.#.#.#.#.#.#########.#.###.###############.#######.#.#####.###.#.#########.#################.#.###.#######.#.#.#########
    \\#####...#.......#...#.#.#.#.#.#.........#...###.............###.......#.#.#...#...#.#...#.......#...........#.....#...#.....###...#.....#...#
    \\#####.###########.###.#.#.#.#.#########.###################.#########.#.#.#.#.###.#.###.#.#######.#########.#.#######.#####.###########.#.#.#
    \\#.....#.....#...#...#.#.#.#.#.#...#.....###...#.....#.......#...#...#...#...#.....#.#...#.......#.........#...#...#...#.....#.......#...#.#.#
    \\#.#####.###.#.#.###.#.#.#.#.#.#.#.#v#######.#.#.###.#.#######.#.#.#.###############.#.#########.#########.#####.#.#.###.#####.#####.#.###.#.#
    \\#.......###.#.#...#.#.#.#.#.#.#.#.>.>.#####.#.#.#...#...#####.#.#.#.###...#...#...#...###.....#.#.....#...#...#.#.#...#.#...#...#...#.....#.#
    \\###########.#.###.#.#.#.#.#.#.#.###v#.#####.#.#.#.#####v#####.#.#.#.###.#.#.#.#.#.#######.###.#.#.###.#v###.#.#.#.###.#.#.#.###v#.#########.#
    \\#...........#...#.#.#.#.#.#.#.#.#...#...#...#.#.#.....>.>.###.#.#.#...#.#.#.#.#.#...#.....###...#...#.>.>.#.#.#.#.#...#.#.#...>.#...#...#...#
    \\#.#############.#.#.#.#.#.#.#.#.#.#####.#.###.#.#######v#.###.#.#.###.#.#.#.#.#.###.#.#############.###v#.#.#.#.#.#.###.#.#####v###.#.#.#.###
    \\#...........#...#.#.#.#.#.#.#...#...###.#.###...#.......#...#.#.#.#...#.#.#.#.#.#...#.....#...#...#.#...#...#...#.#.###...###...###...#...###
    \\###########v#.###.#.#.#.#.#.#######.###.#.#######.#########.#.#.#.#.###.#.#.#.#.#.#######v#.#.#.#.#.#.###########.#.#########.###############
    \\#.......###.>.###.#.#.#.#.#.###...#...#.#.......#.........#.#.#.#.#...#.#.#.#.#.#...#...>.>.#.#.#.#.#...#...#...#...#####...#.#...#...#.....#
    \\#.#####.###v#####.#.#.#.#.#.###.#.###.#.#######.#########.#.#.#.#.###.#.#.#.#.#.###.#.###v###.#.#.#.###.#.#.#.#.#########.#.#.#.#.#.#.#.###.#
    \\#.#...#.....#...#...#...#.#.#...#.....#.........#...#.....#.#.#...#...#.#.#.#.#.#...#.#...###.#.#.#...#...#...#...#.......#.#...#...#...#...#
    \\#.#.#.#######.#.#########.#.#.###################.#.#.#####.#.#####.###.#.#.#.#.#.###.#.#####.#.#.###.###########.#.#######.#############.###
    \\#.#.#.#.......#.........#...#.....#...........#...#.#.....#.#.#.....#...#.#.#.#.#.#...#.....#...#.#...#...........#.#.....#...............###
    \\#.#.#.#.###############.#########.#.#########.#.###.#####.#.#.#.#####.###.#.#.#.#.#.#######.#####.#.###.###########.#.###.###################
    \\#...#.#.#.............#...#.......#.#.........#...#.......#...#.......#...#.#.#.#.#.#.......#...#...###.....#...###...#...#.................#
    \\#####.#.#.###########.###.#.#######.#.###########.#####################.###.#.#.#.#.#.#######.#.###########.#.#.#######.###.###############.#
    \\#.....#.#.........###.....#...#.....#...........#.....#...###.......#...#...#...#...#.........#.#...........#.#.......#.....#.......#.......#
    \\#.#####.#########.###########.#.###############.#####.#.#.###.#####.#.###.#####################.#.###########.#######.#######.#####.#.#######
    \\#.....#.#.........#.....#...#...#...............#####...#.....#.....#...#.#.....................#.............#.......###.....#...#...#.....#
    \\#####.#.#.#########.###.#.#.#####.#############################.#######.#.#.###################################.#########.#####.#.#####.###.#
    \\#...#...#.........#.#...#.#.#...#...............#...............###...#...#.......#.....#...#...#...#.........#.....#.....#...#.#.......#...#
    \\#.#.#############.#.#.###.#.#.#.###############.#.#################.#.###########.#.###.#.#.#.#.#.#.#.#######.#####.#.#####.#.#.#########.###
    \\#.#.............#...#...#.#.#.#.#...#...........#...................#.#.....#.....#.#...#.#.#.#.#.#.#.......#.......#.....#.#...#.....#...###
    \\#.#############.#######.#.#.#.#.#.#.#.###############################.#.###.#.#####.#.###.#.#.#.#.#.#######.#############.#.#####.###.#.#####
    \\#.............#...#.....#.#.#.#.#.#.#.#.........#...............#.....#...#.#.......#.....#...#.#.#.###.....#...###...###...#.....###...#####
    \\#############.###.#.#####.#.#.#.#.#.#.#.#######.#.#############.#.#######.#.###################.#.#.###.#####.#.###.#.#######v###############
    \\#.............###...#...#.#...#...#.#...#.......#.....#...#...#...#...###.#.#...#...###...#.....#.#...#.....#.#.#...#...#...>.#.............#
    \\#.###################.#.#.#########.#####.###########.#.#.#.#.#####.#.###.#.#.#.#.#.###.#.#.#####.###.#####.#.#.#.#####.#.###v#.###########.#
    \\#.....#...#...#...###.#.#...#.......#...#.#...###...#...#...#...#...#...#.#.#.#.#.#.....#...#...#...#.#...#.#.#.#...#...#.###...#...........#
    \\#####.#.#.#.#.#.#.###.#.###.#.#######.#.#v#.#.###.#.###########.#.#####.#.#.#.#.#.###########.#.###.#.#.#.#v#.#.###.#.###.#######.###########
    \\#.....#.#...#.#.#.....#.#...#.#.....#.#.>.>.#...#.#.#...........#.#.....#.#.#.#.#.......#...#.#.#...#.#.#.>.>.#.....#.....#.......#...#...###
    \\#.#####.#####.#.#######.#.###.#.###.#.###v#####.#.#.#v###########.#.#####.#.#.#.#######.#.#.#.#.#.###.#.###v###############.#######.#.#.#.###
    \\#...#...#.....#.......#...#...#.#...#.#...###...#.#.>.>...#.....#.#...###.#.#.#.#...###...#.#.#...###.#...#.#.......###...#.....#...#.#.#.###
    \\###.#.###.###########.#####.###.#.###.#.#####.###.###v###.#.###.#.###.###.#.#.#.#.#.#######.#.#######.###.#.#.#####.###.#.#####.#.###.#.#.###
    \\#...#.#...#...###...#.....#...#.#.....#.#...#...#...#...#...#...#.#...#...#.#.#.#.#.#.....#.#.......#.#...#.#.#.....#...#.......#.#...#.#...#
    \\#.###.#.###.#v###.#.#####.###.#.#######.#.#.###.###.###.#####.###.#.###.###.#.#.#.#.#.###.#.#######.#.#.###.#.#.#####.###########.#.###.###.#
    \\#...#.#...#.#.>...#.......#...#.###...#...#...#.#...###.....#...#.#...#.#...#.#.#.#.#...#...#...#...#...#...#.#.#...#.....#.......#...#.#...#
    \\###.#.###.#.#v#############.###.###.#.#######.#.#.#########.###.#.###.#.#.###.#.#.#.###v#####.#.#.#######.###.#.#.#.#####.#.#########.#.#.###
    \\#...#.###...#...........###.#...#...#.......#.#...#.........###...#...#.#...#.#.#.#...>.>.#...#.#.......#...#.#...#.....#.#.#.........#.#.###
    \\#.###.#################.###.#.###.#########.#.#####.###############.###.###.#.#.#.#####v#.#.###.#######.###.#.#########.#.#.#.#########.#.###
    \\#.....#...#.........#...#...#...#.........#.#.#.....#.....#####...#...#.###.#.#.#.#...#.#.#...#.#...#...#...#.#.........#...#...#...#...#...#
    \\#######.#.#.#######.#.###.#####.#########.#.#.#.#####.###.#####.#.###.#.###.#.#.#.#.#.#.#.###.#.#.#.#.###.###.#.###############.#.#.#.#####.#
    \\#####...#.#...#...#...###.......###.......#...#.....#.###...#...#.#...#...#.#.#.#.#.#...#.....#...#.#.###.....#.........#...###...#.#.#.....#
    \\#####.###.###.#.#.#################.###############.#.#####.#.###.#.#####.#.#.#.#.#.###############.#.#################.#.#.#######.#.#.#####
    \\###...#...###...#.....#.....#.....#.............#...#.###...#.#...#.......#...#.#.#.#.............#...#...###...#.......#.#.#...#...#.#.....#
    \\###.###.#############.#.###.#.###.#############.#.###.###.###.#.###############.#.#.#.###########.#####.#.###.#.#.#######.#.#.#.#.###.#####.#
    \\#...#...###.....#.....#.#...#...#.#...........#.#...#.#...#...#...#.....#.....#...#...#.........#.#.....#.....#...#.....#.#.#.#.#.....#...#.#
    \\#.###.#####.###.#v#####.#.#####.#.#.#########.#.###.#.#.###.#####.#.###.#.###.#########.#######.#.#.###############.###.#.#.#.#.#######v#.#.#
    \\#...#.....#.#...#.>.....#.#...#.#.#.#...#####...###...#.....#...#...#...#.#...#...#...#.......#...#...............#...#...#.#.#.#...#.>.#.#.#
    \\###.#####.#.#.###v#######.#.#.#.#.#.#.#.#####################.#.#####.###.#.###.#.#.#.#######.###################.###.#####.#.#.#.#.#.#v#.#.#
    \\#...#...#...#.#...###.....#.#.#.#.#...#.....#...#...#.......#.#.#...#...#.#...#.#...#.........#...###...........#.#...###...#.#...#...#.#...#
    \\#.###.#.#####.#.#####.#####.#.#.#.#########.#.#.#.#.#.#####.#.#.#.#.###.#.###.#.###############.#.###.#########.#.#.#####.###.#########.#####
    \\#.....#...#...#.#.....#.....#.#.#...###.....#.#.#.#.#...#...#.#...#.....#.#...#.................#...#.....#...#...#.....#.....#.....###...###
    \\#########.#.###.#.#####.#####.#.###.###.#####.#.#.#.###.#.###.###########.#.#######################.#####.#.#.#########.#######.###.#####.###
    \\#.........#.#...#...#...#.....#.#...#...#...#.#...#.###.#.#...#.....#...#.#.###...###...#...........#...#...#.......#...#...###...#.#...#...#
    \\#.#########.#.#####.#.###.#####.#.###.###.#.#.#####.###.#.#.###.###.#.#.#.#.###.#.###.#.#v###########.#.###########.#.###.#.#####.#.#.#.###.#
    \\#.......###.#.....#.#.#...#.....#...#.....#.#.#.....#...#.#.....#...#.#.#.#.#...#.#...#.>.>.#...#...#.#.###...###...#...#.#.......#...#.#...#
    \\#######.###.#####.#.#.#.###.#######.#######.#.#.#####.###.#######.###.#.#.#.#.###.#.#####v#.#.#.#.#.#.#.###.#.###v#####.#.#############.#.###
    \\#.......#...#.....#.#.#...#.#...###...#.....#.#.#...#.#...#...###.###.#.#.#...###...#...#.#.#.#.#.#.#.#.#...#...>.>.#...#.............#.#.###
    \\#.#######.###.#####.#.###.#.#.#.#####.#v#####.#.#.#.#.#.###.#.###v###.#.#.###########.#.#.#.#.#.#.#.#.#.#.#######v#.#.###############.#.#.###
    \\#.......#.....#####.#.###...#.#.#...#.>.>...#.#.#.#.#.#.#...#...>.>.#.#...###...###...#...#...#.#.#...#...#...#...#.#...#.............#...###
    \\#######.###########.#.#######.#.#.#.###v###.#.#.#.#.#.#.#.#######v#.#.#######.#.###.###########.#.#########.#.#.###.###.#.###################
    \\#.....#.........#...#.#...#...#.#.#.#...###.#.#.#.#...#...###.....#...#.......#.....#.........#...#.........#...###.#...#.#.....#...#.......#
    \\#.###.#########.#.###.#.#.#.###.#.#.#.#####.#.#.#.###########.#########.#############.#######.#####.###############.#.###.#.###.#.#.#.#####.#
    \\#...#...........#.....#.#.#...#.#.#.#.....#.#.#.#.###...#...#.........#.#...#.........#.......#...#.#.......#...###...###...###...#...#.....#
    \\###.###################.#.###.#.#.#.#####.#.#.#.#.###.#.#.#.#########.#.#.#.#.#########.#######.#.#.#.#####.#.#.#######################.#####
    \\###.........#...#...###.#.....#.#.#.......#...#.#.#...#...#.###...#...#.#.#.#.#.......#.#...#...#.#...#.....#.#.#...#...###...#.........#####
    \\###########.#.#.#.#.###.#######.#.#############.#.#.#######.###.#.#.###.#.#.#.#.#####.#.#.#.#.###.#####.#####.#.#.#.#.#.###.#.#.#############
    \\#.....#.....#.#...#...#...#...#.#...........###...#.......#...#.#.#...#...#.#.#.....#...#.#.#.#...#...#.......#.#.#...#.#...#.#.............#
    \\#.###.#.#####.#######.###.#.#.#.###########.#############.###.#.#.###.#####.#.#####.#####.#.#.#.###.#.#########.#.#####.#.###.#############.#
    \\#...#...#...#...#.....#...#.#.#...#.......#...#...........###.#.#.....#...#.#.#.....#...#.#.#.#.###.#.#...#.....#.#.....#...#...........#...#
    \\###.#####.#.###.#.#####.###.#.###.#.#####.###.#.#############.#.#######.#.#.#.#.#####.#.#.#.#.#.###.#.#.#.#v#####.#.#######.###########.#.###
    \\#...#...#.#...#.#.#...#.....#...#.#.#...#.....#.......#.....#...###...#.#.#...#.....#.#...#.#.#...#.#.#.#.>.>.#...#.#.....#...........#...###
    \\#.###.#.#.###.#.#.#.#.#########.#.#.#.#.#############.#.###.#######.#.#.#.#########.#.#####.#.###.#.#.#.#####.#.###.#.###.###########.#######
    \\#...#.#...#...#.#.#.#.#.........#...#.#...#...#.....#...#...#.....#.#...#...#...#...#.###...#...#.#.#...###...#.#...#.#...###.........#...###
    \\###.#.#####.###.#.#.#.#.#############.###.#.#.#.###.#####.###.###.#.#######.#.#.#.###.###.#####.#.#.#######.###.#.###.#.#####.#########.#.###
    \\###.#...###.....#...#.#.#.....###...#.#...#.#.#...#.#.....###...#.#...#.....#.#.#...#...#...#...#.#.......#...#.#...#.#.#...#.........#.#.###
    \\###.###.#############.#.#.###.###.#.#.#.###.#.###.#.#.#########.#.###.#.#####.#.###v###.###.#.###.#######.###.#.###.#.#.#.#.#########.#.#.###
    \\###...#...#...........#...###.....#...#.#...#.###.#.#.......###.#.#...#.#...#.#.#.>.>.#.#...#...#.#.....#...#...###.#.#.#.#.###.......#.#.###
    \\#####.###.#.###########################.#.###.###.#.#######.###.#.#.###.#.#.#.#.#.###.#.#.#####.#.#.###.###.#######.#.#.#.#.###.#######.#.###
    \\#####.....#...........#...###...........#...#.#...#.#.......#...#.#.###.#.#...#.#...#.#.#.....#.#...###...#.#.......#.#...#...#...#...#.#...#
    \\#####################.#.#.###v#############.#.#.###.#.#######.###.#.###.#.#####.###.#.#.#####.#.#########.#.#.#######.#######.###.#.#.#.###.#
    \\#.....................#.#.#.>.>.###...#...#.#.#.#...#.....#...#...#...#.#.#.....#...#.#.#.....#...#.....#...#.......#.###.....#...#.#.#.#...#
    \\#.#####################.#.#.###.###.#.#.#.#.#.#.#.#######v#.###.#####.#.#.#.#####.###.#.#.#######.#.###.###########.#.###.#####v###.#.#.#.###
    \\#...#.....#...........#.#.#.#...#...#.#.#.#.#.#.#.#.....>.>.#...#...#.#.#.#.....#.###.#.#.......#...#...#...........#...#.....>.#...#.#.#.###
    \\###.#.###.#.#########.#.#.#.#.###.###.#.#.#.#.#.#.#.#########.###.#.#.#.#.#####.#.###.#.#######.#####.###.#############.#######v#.###.#.#.###
    \\#...#.#...#.#.........#.#.#.#.#...###.#.#.#.#.#.#.#.........#...#.#.#.#.#.#.....#...#.#.#.......#.....###...#.....#...#.#.......#...#.#.#.###
    \\#.###.#.###.#.#########.#.#.#.#.#####.#.#.#.#.#.#.#########.###.#.#.#.#.#.#.#######.#.#.#.#######.#########.#.###.#.#.#.#.#########.#.#.#.###
    \\#.....#.....#...........#...#...#####...#...#...#...........###...#...#...#.........#...#.........#########...###...#...#...........#...#...#
    \\###########################################################################################################################################.#
;