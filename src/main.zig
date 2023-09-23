const std = @import("std");
const Day = @import("day.zig");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();

    // Day 1: Calorie Counting
    var d1 = Day.Day1.init("Day 1: Calorie Counting");
    try d1.run(allocator);
}
