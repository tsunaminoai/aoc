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

fn part1(input: []const u8, alloc: Allocator) !u32 {
    _ = alloc;
    _ = input;
    return 0;
}

fn part2(input: []const u8, alloc: Allocator) !u32 {
    _ = alloc;
    _ = input;
    return 0;
}
