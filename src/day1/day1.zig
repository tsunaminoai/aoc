const std = @import("std");
const Day = @import("../day.zig");
const Day1 = @This();

name: []const u8,

pub fn init(name: []const u8) Day1 {
  var d = Day1{ .name = name };
  return d;
}
pub fn day(self: *Day1) Day {
  return Day.init(self, run);
}
pub fn run(self: *Day1, allocator: std.mem.Allocator) Day.DayErrors!void {
    std.debug.print("{s}\n", .{self.name});

    const file = try std.fs.cwd().openFile("src/day1/input", .{});
    defer file.close();

    const read_buffer = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(read_buffer);

    var it = std.mem.split(u8, read_buffer, "\n");

    var elves = std.ArrayList(u32).init(allocator);
    defer elves.deinit();

    var avg: u32 = 0;
    while (it.next()) |line| {
        var int = std.fmt.parseInt(u32, line, 10) catch |err| {
            if (err == error.InvalidCharacter) {
                try elves.append(avg);
                avg = 0;
                continue;
            }
            return err;
        };
        avg += int;
    }
    var elfList = try elves.toOwnedSlice();
    std.mem.sort(u32, elfList, {}, comptime std.sort.asc(u32));
    var total: u32 = 0;
    for (elfList.len - 3..elfList.len) |i| {
        total += elfList[i];
    }
    std.debug.print("Total: {}\n", .{total});
}
