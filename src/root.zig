const std = @import("std");
const testing = std.testing;

pub const day = @import("aoc").day;

pub const atoi = stringDigitsToNumber;

pub fn stringDigitsToNumber(input: []const u8) !u32 {
    var ret: u32 = 0;
    for (input) |c| {
        const d: u8 = std.fmt.charToDigit(c, 10) catch |err| {
            std.debug.print("atoi Invalid string passed: \"{s}\"\n", .{input});
            return err;
        };
        ret = ret * 10 + d;
        // std.debug.print("c: {c} d: {} ret: {}\n", .{ c, d, ret });
    }
    return ret;
}

pub fn atoi2(comptime T: type, input: []const u8) !T {
    var ret: u64 = 0;
    for (input) |c| {
        const d: u8 = std.fmt.charToDigit(c, 10) catch |err| {
            std.debug.print("atoi Invalid string passed: \"{s}\"\n", .{input});
            return err;
        };
        ret = ret * 10 + d;
        // std.debug.print("c: {c} d: {} ret: {}\n", .{ c, d, ret });
    }
    return @as(T, @intCast(ret));
}

test {
    testing.refAllDecls(@This());
}
