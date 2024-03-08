const std = @import("std");
const atoi = @import("root.zig").atoi2;
pub const Allocator = std.mem.Allocator;
pub const testing = std.testing;
pub const Array = std.ArrayList;

pub fn day(writer: anytype, alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("inputs/day18.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(alloc, 100_000);
    try writer.print("Result1: {}\n", .{try part1(content, alloc)});
    try writer.print("Result2: {}\n", .{try part2(content, alloc)});
}

fn part2(input: []const u8, alloc: Allocator) !u32 {
    _ = alloc;
    _ = input;
    return 0;
}

const Direction = enum(u8) {
    up = 'U',
    down = 'D',
    left = 'L',
    right = 'R',
};
const Instruction = struct {
    dir: Direction,
    amount: u32,
};
fn part1(input: []const u8, alloc: Allocator) !u32 {
    var sum: u32 = 0;
    var lines = std.mem.splitAny(u8, input, "\n");
    var instructions = std.ArrayList(Instruction).init(alloc);
    defer instructions.deinit();

    while (lines.next()) |line| {
        try instructions.append(.{
            .dir = @enumFromInt(line[0]),
            .amount = try atoi(u8, line[2..3]),
        });
        sum += 1;
    }
    return sum;
}
test "part1" {
    const allocator = std.testing.allocator;
    const input =
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    ;
    try std.testing.expectEqual(try part1(input, allocator), 62);
}
