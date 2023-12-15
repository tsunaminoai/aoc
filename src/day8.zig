/// once again running into seg faults. I did take a look at someone else's tree
///  implementation (https://github.com/rylmovuk/zig-tree/blob/master/tree.zig)
/// Took some time to refactor that project to compile under zig >= 0.11 and it /also/
/// segfaults. Leads me to suspect I'm not using stringhashmaps correctly or there
/// is a bug in the compiler. I'll default to assuming the former.
const std = @import("std");
const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const testing = std.testing;

const Direction = enum { right, left };

const Node = struct {
    id: []const u8,
    right: ?*Node = null,
    left: ?*Node = null,

    pub fn getNext(self: *Node, direction: Direction) *Node {
        return switch (direction) {
            .right => self.right.?,
            .left => self.left.?,
        };
    }
    pub fn init(alloc: Allocator, id: []const u8) !*Node {
        const n = try alloc.create(Node);
        n.*.id = id;
        return n;
    }
};

const Tree = struct {
    nodes: std.StringHashMap(Node),
    arena: Arena,
    head: ?*Node = null,

    pub fn init(alloc: Allocator) Tree {
        var arena = Arena.init(alloc);
        const a = arena.allocator();
        const t = Tree{
            .nodes = std.StringHashMap(Node).init(a),
            .arena = arena,
        };
        return t;
    }

    fn getFromHashMap(self: *Tree, id: []const u8) !*Node {
        var search = try self.nodes.getOrPut(id);
        if (!search.found_existing) {
            const alloc = self.arena.allocator();

            search.value_ptr = try Node.init(alloc, id);
        }
        return search.value_ptr;
    }

    pub fn addNode(self: *Tree, string: []const u8) !void {
        const id = string[0..3];
        const leftId = string[7..10];
        const rightId = string[12..15];
        std.debug.print("processing: {s} = ({s},{s})\n", .{ id, leftId, rightId });

        const writeNode = try self.getFromHashMap(id);
        if (self.head == null)
            self.head = writeNode;

        const leftNode = try self.getFromHashMap(leftId);
        const rightNode = try self.getFromHashMap(rightId);

        writeNode.left = leftNode;
        writeNode.right = rightNode;
    }

    pub fn deinit(self: *Tree) void {
        // self.nodes.deinit();
        self.arena.deinit();
    }

    pub fn print(self: *Tree) !void {
        for (self.nodes.keys(), 0..) |n, i|
            std.debug.print("node {}: {s}\n", .{ i, self.nodes.get(n).?.id });
    }
    pub fn followSteps(self: *Tree, needle: []const u8, directions: []const u8) u32 {
        var steps: u32 = 0;
        var found: []const u8 = "   ";
        var currentNode = self.head.?;

        while (!std.mem.eql(u8, needle, found)) {
            const dir: Direction = switch (directions[@mod(steps, (directions.len - 1))]) {
                'R' => .right,
                'L' => .left,
                else => unreachable,
            };
            found = currentNode.id;
            std.debug.print("step: {}: On {s} and going {s}\n", .{ steps, found, @tagName(dir) });

            currentNode = currentNode.getNext(dir);
            steps += 1;
        }
        return steps;
    }
    pub fn load(self: *Tree, input: []const u8) !void {
        var iter = std.mem.split(u8, input, "\n");
        const directions = iter.next().?;
        _ = directions;
        _ = iter.next();
        while (iter.next()) |entry|
            try self.addNode(entry);
    }
};

test "tree" {
    var t = Tree.init(testing.allocator);
    defer t.deinit();

    try t.addNode("AAA = (BBB, CCC)");
    try t.addNode("BBB = (DDD, EEE)");
    try t.addNode("CCC = (ZZZ, GGG)");
    try t.addNode("GGG = (ZZZ, GGG)");
    try testing.expectEqual(t.followSteps("CCC", "RL"), 2);
}

pub fn day(writer: anytype, alloc: Allocator) !void {
    _ = alloc;
    _ = writer;
}

test "example 1" {
    const INPUT1 =
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    var t = Tree.init(testing.allocator);
    defer t.deinit();
    try t.load(INPUT1);
    const result1 = t.followSteps("ZZZ", "RL");
    const answer1 = 2;
    try testing.expectEqual(result1, answer1);
}
test "example 2" {
    const INPUT2 =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    var t = Tree.init(testing.allocator);
    defer t.deinit();

    try t.load(INPUT2);
    const result = t.followSteps("ZZZ", "LLR");
    const answer = 2;
    try testing.expectEqual(result, answer);
}
