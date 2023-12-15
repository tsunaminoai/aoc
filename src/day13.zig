const std = @import("std");
pub const Allocator = std.mem.Allocator;
pub const testing = std.testing;
pub const Array = std.ArrayList;

pub fn day(writer: anytype, alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("inputs/day13.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(alloc, 100_000);
    try writer.print("Result: {}\n", .{try part1(content, alloc)});
}

fn part1(input: []const u8, alloc: Allocator) !u32 {
    _ = input;
    _ = alloc;
    return 0;
}

const Row = []bool;
const Col = Row;

fn parsePattern(input: []const u8, alloc: Allocator) !Array(Col) {
    var iter = std.mem.split(u8, input, "\n");

    const row1 = iter.peek();
    const width = if (row1) |r| r.len else return error.NoRow;

    var rows = Array(Col).init(alloc);

    while (iter.next()) |line| {
        var r = try alloc.alloc(bool, width);
        // defer alloc.free(r);

        for (line, 0..) |char, idx| {
            r[idx] = if (char == '#') true else false;
        }
        try rows.append(r);
    }
    return rows;
}

const ResTag = enum { row, col };
const Result = union(ResTag) {
    row: usize,
    col: usize,
};
fn reflect(pattern: Array(Col), alloc: Allocator) !Result {
    _ = alloc;

    const width = pattern.items[0].len;
    const height = pattern.items.len;
    var checkRow = (height - 1) / 2;
    var checkCol = (width - 1) / 2;
    std.debug.print("width:{} height: {} row: {}, col: {}\n", .{ width, height, checkRow, checkCol });
    for (checkRow - 1..checkRow + 1) |i| {
        std.debug.print("Checking row: {}\n", .{i});

        if (std.mem.eql(bool, pattern.items[i], pattern.items[i + 1]))
            return Result{ .row = i };
    }

    for (checkCol - 1..checkCol + 1) |i| {
        std.debug.print("Checking col: {}\n", .{i});

        var check: usize = 0;
        for (pattern.items, 0..) |row, j| {
            _ = j;

            check += if (row[i] == row[i + 1]) 1 else 0;
        }
        if (check == height) {
            return Result{ .col = i };
        }
    }

    return Result{ .col = 0 };
}
test "pattern" {
    const p = try parsePattern(Sample1, testing.allocator);
    defer {
        for (p.items) |r|
            testing.allocator.free(r);
        p.deinit();
    }

    const res = try reflect(p, testing.allocator);
    switch (res) {
        .col => std.debug.print("{any}\n", .{res}),
        .row => std.debug.print("{any}\n", .{res}),
    }
}
const Sample1 =
    \\#.##..##.
    \\..#.##.#.
    \\##......#
    \\##......#
    \\..#.##.#.
    \\..##..##.
    \\#.#.##.#.
;
