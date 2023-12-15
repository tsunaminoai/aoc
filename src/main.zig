const std = @import("std");
const aoc = @import("day");
const config = @import("config");
const timing = @import("timing");
const time = std.time;

var startTime: i128 = 0;

pub fn main() !void {
    if (timing.timing) {
        startTime = time.nanoTimestamp();
    }
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

    if (timing.timing) {
        const stop = time.nanoTimestamp();
        std.debug.print("Took: {}ns\n", .{stop - startTime});
    }
}
