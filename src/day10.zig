const std = @import("std");
const Alloctor = std.mem.Allocator;
const testing = std.testing;
const Array = std.ArrayList;

pub fn day(writer: anytype, alloc: std.mem.Allocator) !void {
    var file = try std.fs.cwd().openFile("inputs/day10.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(alloc, 100_000);
    try writer.print("Depth needed: {}\n", .{try part1(content, alloc)});
}

pub fn part1(input: []const u8, alloc: Alloctor) !u32 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const ally = arena.allocator();
    var g = Graph.init(ally);
    defer g.deinit();

    try g.processInput(input);

    // std.debug.print("{}", .{g});
    const depth = try g.bredth();
    return depth;
}

const Direction = enum {
    north,
    west,
    south,
    east,
};
const Connection = struct {
    dest: ?*Node = null,
    dir: Direction,
};

const Node = struct {
    char: u8,
    discovered: bool = false,
    distanceFromStart: u32 = 0,
    alloc: Alloctor,
    ptr: *Node = undefined,

    adjacents: Array(Connection),

    /// | is a vertical pipe connecting north and south.
    /// - is a horizontal pipe connecting east and west.
    /// L is a 90-degree bend connecting north and east.
    /// J is a 90-degree bend connecting north and west.
    /// 7 is a 90-degree bend connecting south and west.
    /// F is a 90-degree bend connecting south and east.
    /// . is ground; there is no pipe in this tile.
    /// S is the starting position of the animal; there is a pipe on this
    /// tile, but your sketch doesn't show what shape the pipe has.
    pub fn init(char: u8, alloc: Alloctor) !*Node {
        var node = try alloc.create(Node);
        node.* = Node{
            .char = char,
            .alloc = alloc,
            .adjacents = Array(Connection).init(alloc),
        };
        switch (char) {
            '|' => {
                try node.adjacents.append(.{ .dir = .north });
                try node.adjacents.append(.{ .dir = .south });
            },
            '-' => {
                try node.adjacents.append(.{ .dir = .east });
                try node.adjacents.append(.{ .dir = .west });
            },
            'L' => {
                try node.adjacents.append(.{ .dir = .north });
                try node.adjacents.append(.{ .dir = .east });
            },
            'J' => {
                try node.adjacents.append(.{ .dir = .north });
                try node.adjacents.append(.{ .dir = .west });
            },
            '7' => {
                try node.adjacents.append(.{ .dir = .west });
                try node.adjacents.append(.{ .dir = .south });
            },
            'F' => {
                try node.adjacents.append(.{ .dir = .east });
                try node.adjacents.append(.{ .dir = .south });
            },
            '.' => {
                node.discovered = true;
            },
            'S' => {
                try node.adjacents.append(.{ .dir = .north });
                try node.adjacents.append(.{ .dir = .south });
                try node.adjacents.append(.{ .dir = .east });
                try node.adjacents.append(.{ .dir = .west });
            },
            else => {
                std.debug.print("Unknown character input: {c}\n", .{char});
                return error.UnknownChar;
            },
        }
        node.ptr = node;
        return node;
    }
};

const GraphT = struct {
    verticiesLen: usize,
    adjacents: [][]bool,
    const Self = @This();
    pub fn init() Self {}
};
const Graph = struct {
    start: ?*Node = null,
    nodes: Array(*Node),
    alloc: Alloctor,
    width: usize = 0,
    height: usize = 0,

    const Self = @This();
    pub fn init(alloc: Alloctor) Self {
        return Self{
            .nodes = Array(*Node).init(alloc),
            .alloc = alloc,
        };
    }
    pub fn deinit(self: *Self) void {
        self.nodes.deinit();
    }

    /// for this we will traverse right and down and only create links for objects
    /// that are left and up (so they should already exist to make a link)
    pub fn processLine(self: *Self, line: []const u8) !void {
        const currentLineIdx = self.height;
        // std.debug.print("Processing line of len {}: {s}\n", .{ line.len, line });
        for (line, 0..) |char, idx| {
            const newNode = try self.addNode(char);
            if (char == 'S')
                self.start = newNode;

            if (self.height > 0) {
                const north = self.nodes.items[(currentLineIdx - 1) * self.width + idx];
                try newNode.adjacents.append(.{ .dir = .north, .dest = north });
                try north.adjacents.append(.{ .dir = .south, .dest = newNode });
            }
            if (idx > 0) {
                const west = self.nodes.items[currentLineIdx * self.width + idx - 1];
                try newNode.adjacents.append(.{ .dir = .west, .dest = west });
                try west.adjacents.append(.{ .dir = .east, .dest = newNode });
            }
        }

        if (self.height == 0)
            self.setWidth();
        self.height += 1;
    }
    pub fn setWidth(self: *Self) void {
        self.width = self.nodes.items.len;
        std.debug.print("Setting width to: {}\n", .{self.width});
    }

    pub fn addNode(self: *Self, char: u8) !*Node {
        const newNode = try Node.init(char, self.alloc);
        try self.nodes.append(newNode);

        return newNode;
    }

    pub fn getMaxDistance(self: Self) u32 {
        var max: u32 = 0;
        for (self.nodes.items) |n| {
            if (n.distanceFromStart > max and n.discovered == true)
                max = n.distanceFromStart;
        }
        return max;
    }
    pub fn format(
        self: Self,
        fmt: []const u8,
        options: anytype,
        writer: anytype,
    ) !void {
        _ = options;
        const show: u1 = if (std.mem.eql(u8, fmt, "dist")) 0 else 1;

        try writer.writeAll("Nodes\n");
        for (self.nodes.items, 1..) |n, i| {
            if (n.char == 'S') {
                try writer.print(" {c} ", .{n.char});
                continue;
            }
            switch (show) {
                0 => {
                    const max = self.getMaxDistance();
                    _ = max;

                    try writer.print("{d:02} ", .{n.distanceFromStart});
                },
                1 => try writer.print("{c}", .{n.char}),
            }

            if (@mod(i, self.width) == 0)
                try writer.writeAll("\n");
        }
        try writer.print("Graph size: {}, width: {}, height: {}\n", .{
            self.nodes.items.len,
            self.width,
            self.height,
        });
    }
    pub fn processInput(self: *Self, input: []const u8) !void {
        var iter = std.mem.split(u8, input, "\n");
        while (iter.next()) |line|
            try self.processLine(line);
    }
    fn bredth(self: *Self) !u32 {
        var queue = try self.alloc.alloc(*Node, self.nodes.items.len);
        defer self.alloc.free(queue);

        var front: usize = 0;
        var back: usize = 0;
        var node = self.start.?;
        node.discovered = true;

        back += 1;
        queue[back] = node;

        var steps: u32 = 1;

        outer: while (front != back and back < queue.len) {
            front += 1;
            node = queue[front];

            // node.discovered = true;
            node.distanceFromStart = steps;

            // std.debug.print("front: {}, back: {}\nprocessing: {c} {}\n", .{
            //     front,
            //     back,
            //     node.char,
            //     node.distanceFromStart,
            // });
            for (node.adjacents.items) |adj| {
                if (adj.dest) |d| {
                    if (d.char == 'S' and steps > 10)
                        break :outer;
                    if (!d.discovered) {
                        back += 1;
                        d.discovered = true;
                        queue[back] = d;
                        node.distanceFromStart += 1;
                    }
                }
            }
            steps += 1;
        }

        return self.getMaxDistance() / 2;
    }
};

test "day10 BFS" {
    const INPUT =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const alloc = arena.allocator();
    var g = Graph.init(alloc);
    defer g.deinit();

    try g.processInput(INPUT);
    const out = try g.bredth();
    std.debug.print("{dist} {d}", .{ g, out });
}
test "day10 sample 1" {
    const INPUT =
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    ;
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const alloc = arena.allocator();
    var g = Graph.init(alloc);
    defer g.deinit();

    try g.processInput(INPUT);

    const depth = try g.findDepth();
    std.debug.print("{dist}", .{g});
    // std.debug.print("depth: {}\n", .{depth / 2});
    try testing.expectEqual(depth, 4);
}

test "day10 sample 2" {
    const INPUT =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const alloc = arena.allocator();
    var g = Graph.init(alloc);
    defer g.deinit();

    try g.processInput(INPUT);

    const depth = try g.findDepth();
    std.debug.print("{dist}", .{g});
    // std.debug.print("depth: {}\n", .{depth / 2});
    try testing.expectEqual(depth, 8);
}
test "graph" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const alloc = arena.allocator();
    var g = Graph.init(alloc);
    defer g.deinit();

    try g.processLine(".....");
    try testing.expectEqual(g.nodes.items.len, 5);
    try g.processLine(".S-7.");
    try testing.expectEqual(g.nodes.items.len, 10);
    const secondRow = g.nodes.items[5..10];
    try testing.expectEqual(secondRow[2].char, '-');
    try testing.expectEqual(secondRow[2].west.?.dest, secondRow[1].ptr);
    try testing.expectEqual(secondRow[2].east.?.dest, secondRow[3].ptr);
    try testing.expectEqual(secondRow[3].west.?.dest, secondRow[2].ptr);
}
