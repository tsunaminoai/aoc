const std = @import("std");
const aoc = @import("aoc");

pub fn main() !void {
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    aoc.day1(stdout) catch |err| {
        try stdout.print("Error: {s}", .{@errorName(err)});
    };
    try bw.flush();
}
