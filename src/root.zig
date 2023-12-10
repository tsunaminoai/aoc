const std = @import("std");
const testing = std.testing;

pub const atoi = stringDigitsToNumber;

/// The newly-improved calibration document consists of lines of text; each
/// line originally contained a specific calibration value that the Elves now
/// need to recover. On each line, the calibration value can be found by
/// combining the first digit and the last digit (in that order) to form a
/// single two-digit number.
///
/// For example:
///
/// 1abc2
/// pqr3stu8vwx
/// a1b2c3d4e5f
/// treb7uchet
/// In this example, the calibration values of these four lines are 12, 38, 15,
/// and 77. Adding these together produces 142.
///
/// Consider your entire calibration document. What is the sum of all of the
/// calibration values?
const Allocator = std.mem.Allocator;
pub fn calibrationValue(alloc: Allocator, input: []const u8) !u32 {
    if (input.len == 0) {
        return error.EmptyInput;
    }
    var ret: u32 = 0;
    var digits = std.ArrayList(u8).init(alloc);
    defer digits.deinit();

    for (input, 0..) |c, i| {
        if (std.ascii.isDigit(c)) {
            try digits.append(c);
        }
        if (stringToInt(input[i..])) |d|
            try digits.append(std.fmt.digitToChar(d, .lower));
    }
    if (digits.items.len == 0) {
        std.debug.print("No digits found in string \"{s}\"\n", .{input});
        return error.NoDigitsFound;
    }
    {
        const first: u32 = try std.fmt.charToDigit(digits.items[0], 10);
        ret = 10 * first;
    }
    {
        const second: u32 = try std.fmt.charToDigit(digits.getLast(), 10);
        ret += second;
    }

    return ret;
}

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
pub fn day1(writer: anytype) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const alloc = gpa.allocator();
    var input = try std.fs.cwd().openFile("inputs/day1.txt", .{});
    defer input.close();

    var sum: u32 = 0;
    const text = try alloc.alloc(u8, try input.getEndPos());
    defer alloc.free(text);

    _ = try input.readAll(text);

    var iter = std.mem.split(u8, text, "\n");
    while (iter.next()) |i| {
        // std.debug.print("{s}\n", .{i});
        sum += try calibrationValue(alloc, i);
    }
    try writer.print("sum: {}\n", .{sum});
}

pub fn stringToInt(input: []const u8) ?u8 {
    const len = input.len;
    if (len < 3)
        return null;
    if (std.mem.eql(u8, input[0..3], "one"))
        return @intCast(1);
    if (std.mem.eql(u8, input[0..3], "two"))
        return @intCast(2);
    if (std.mem.eql(u8, input[0..3], "six"))
        return @intCast(6);
    if (len < 4)
        return null;
    if (std.mem.eql(u8, input[0..4], "four"))
        return @intCast(4);
    if (std.mem.eql(u8, input[0..4], "five"))
        return @intCast(5);
    if (std.mem.eql(u8, input[0..4], "nine"))
        return @intCast(9);
    if (len < 5)
        return null;
    if (std.mem.eql(u8, input[0..5], "three"))
        return @intCast(3);
    if (std.mem.eql(u8, input[0..5], "seven"))
        return @intCast(7);
    if (std.mem.eql(u8, input[0..5], "eight"))
        return @intCast(8);
    return null;
}

test "Day1" {
    try testing.expectEqual(try calibrationValue(testing.allocator, "1abc2"), 12);
    try testing.expectEqual(try calibrationValue(testing.allocator, "pqr3stu8vwx"), 38);
    try testing.expectEqual(try calibrationValue(testing.allocator, "a1b2c3d4e5f"), 15);
    try testing.expectEqual(try calibrationValue(testing.allocator, "treb7uchet"), 77);
    try testing.expectEqual(try calibrationValue(testing.allocator, "two1nine"), 29);
    try testing.expectEqual(try calibrationValue(testing.allocator, "eightwothree"), 83);
    try testing.expectEqual(try calibrationValue(testing.allocator, "4nineeightseven2"), 42);
}
test "stringtoint" {
    try testing.expectEqual(stringToInt("one1"), 1);
    try testing.expectEqual(stringToInt("seven"), 7);
    try testing.expectEqual(stringToInt("eight"), 8);
    try testing.expectEqual(stringToInt("six"), 6);
    try testing.expectEqual(stringToInt("1"), null);
}
test {
    testing.refAllDecls(@This());
}
