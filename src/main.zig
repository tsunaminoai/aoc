const std = @import("std");
const aoc = @import("aoc");

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    try stdout.writeAll("Day 1\n");
    aoc.day1(stdout) catch |err| {
        try stdout.print("Error: {s}", .{@errorName(err)});
    };
    try stdout.writeAll("------\n");

    try stdout.writeAll("Day 2\n");

    aoc.day2(stdout, arena.allocator()) catch |err| {
        try stdout.print("Error: {s}", .{@errorName(err)});
    };

    try stdout.writeAll("------\n");

    try stdout.writeAll("Day 3\n");

    aoc.day3(stdout, arena.allocator()) catch |err| {
        try stdout.print("Error: {s}", .{@errorName(err)});
    };

    try stdout.writeAll("------\n");

    try stdout.writeAll("Day 4\n");

    aoc.day4(stdout, arena.allocator()) catch |err| {
        try stdout.print("Error: {s}", .{@errorName(err)});
    };
    try bw.flush();

    try stdout.writeAll("------\n");

    try stdout.writeAll("Day 6\n");

    aoc.day6(stdout, arena.allocator()) catch |err| {
        try stdout.print("Error: {s}", .{@errorName(err)});
    };

    try stdout.writeAll("------\n");

    try stdout.writeAll("Day 7\n");

    aoc.day7(stdout, arena.allocator()) catch |err| {
        try stdout.print("Error: {s}", .{@errorName(err)});
    };
    try bw.flush();
}
