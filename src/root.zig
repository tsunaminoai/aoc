const std = @import("std");
const testing = std.testing;

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

    for (input) |c| {
        if (std.ascii.isDigit(c)) {
            try digits.append(c);
        }
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
        const d: u8 = try std.fmt.charToDigit(c, 10);
        ret = ret * 10 + d;
        std.debug.print("c: {c} d: {} ret: {}\n", .{ c, d, ret });
    }
    return ret;
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

test "Day1" {
    try testing.expectEqual(try calibrationValue(testing.allocator, "1abc2"), 12);
    try testing.expectEqual(try calibrationValue(testing.allocator, "pqr3stu8vwx"), 38);
    try testing.expectEqual(try calibrationValue(testing.allocator, "a1b2c3d4e5f"), 15);
    try testing.expectEqual(try calibrationValue(testing.allocator, "treb7uchet"), 77);
}
