const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

pub fn day9(writer: anytype, alloc: std.mem.Allocator) !void {
    var file = try std.fs.cwd().openFile("inputs/day9.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(alloc, 100_000);
    const ret = try part1(content, alloc);
    try writer.print("Sum of all evil: {}\n", .{ret});
}

fn nextSequence(input: std.ArrayList(i32), alloc: Allocator) !std.ArrayList(i32) {
    var next = std.ArrayList(i32).init(alloc);

    for (input.items, 0..) |n, i| {
        var j: i32 = 0;
        if (i < input.items.len - 1)
            j = input.items[i + 1]
        else
            break;
        try next.append(j - n);
    }
    return next;
}

fn seqChain(in: std.ArrayList(i32), alloc: Allocator) !std.ArrayList(std.ArrayList(i32)) {
    var check = in;
    var chain = std.ArrayList(std.ArrayList(i32)).init(alloc);
    try chain.append(in);
    while (std.mem.count(i32, check.items, &[_]i32{0}) != check.items.len) {
        const ret = try nextSequence(check, alloc);
        try chain.append(ret);
        check = ret;
    }
    return chain;
}

fn convertString(string: []const u8, alloc: Allocator) !std.ArrayList(i32) {
    var ret = std.ArrayList(i32).init(alloc);
    var iter = std.mem.tokenize(u8, string, " ");

    while (iter.next()) |n|
        try ret.append(try std.fmt.parseInt(i32, n, 10));
    return ret;
}

fn decompose(string: []const u8, alloc: Allocator) !std.ArrayList(std.ArrayList(i32)) {
    var iter = std.mem.tokenize(u8, string, "\n");
    var seqs = std.ArrayList(std.ArrayList(i32)).init(alloc);
    while (iter.next()) |line| {
        const seq = try convertString(line, alloc);
        try seqs.append(seq);
    }
    return seqs;
}

fn extrapolate(chain: std.ArrayList(std.ArrayList(i32))) !i32 {
    const idx: i8 = @intCast(chain.items.len - 1);
    _ = idx;
    var last: i32 = 0;
    const items = chain.items;
    var ret: i32 = 0;

    std.mem.reverse(std.ArrayList(i32), items);
    for (items) |*item| {
        const lastVal = item.getLast();
        const newVal = lastVal + last;
        last = newVal;
        try item.append(newVal);
        ret = newVal;
    }
    return ret;
}

pub fn part1(input: []const u8, alloc: Allocator) !i32 {
    const sequences = try decompose(input, alloc);
    var sum: i32 = 0;
    for (sequences.items) |seq| {
        // std.debug.print("Processing: {any}\n", .{seq.items});
        const chain = try seqChain(seq, alloc);
        sum += try extrapolate(chain);
        // for (chain.items) |c|
        //     std.debug.print("\t{any}\n", .{c.items});
    }
    return sum;
}

test "sequence" {
    const INPUT =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ;

    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const conv = try convertString("0 3 6 9 12 15", alloc);
    try testing.expectEqualDeep(conv.items, @constCast(&[_]i32{ 0, 3, 6, 9, 12, 15 }));

    const next: std.ArrayList(i32) = try nextSequence(conv, alloc);
    try testing.expectEqualDeep(next.items, @constCast(&[_]i32{ 3, 3, 3, 3, 3 }));

    const seqs = try decompose(INPUT, alloc);
    try testing.expectEqual(seqs.items.len, 3);

    const chain = try seqChain(conv, alloc);
    try testing.expectEqual(chain.items.len, 3);

    const res = try extrapolate(chain);
    try testing.expectEqual(res, 18);
}

test "day9" {
    const INPUT =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ;
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const answer = 114;

    const ret = try part1(INPUT, alloc);
    try testing.expectEqual(ret, answer);
}
