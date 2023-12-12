const std = @import("std");
const aoc = @import("day");
const config = @import("config");

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

    try stdout.print("Day {s}\n", .{config.DAY});
    try stdout.writeAll("------\n");
    try aoc.day(stdout, arena.allocator());

    try bw.flush();
}
