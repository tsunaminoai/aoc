const std = @import("std");
const atoi = @import("root.zig").atoi2;
pub const Allocator = std.mem.Allocator;
pub const testing = std.testing;
pub const Array = std.ArrayList;

pub fn day(writer: anytype, alloc: Allocator) !void {
    var file = try std.fs.cwd().openFile("inputs/day15.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(alloc, 100_000);
    try writer.print("Result1: {}\n", .{try part1(content, alloc)});
    try writer.print("Result2: {}\n", .{try part2(content, alloc)});
}

fn part1(input: []const u8, alloc: Allocator) !u32 {
    _ = alloc;

    var sum: u32 = 0;
    var iter = std.mem.tokenize(u8, input, ",");
    while (iter.next()) |n|
        sum += hash(n);
    return sum;
}

fn part2(input: []const u8, alloc: Allocator) !u32 {
    try initBoxes(alloc);
    defer deinitBoxes(alloc);
    return try runTape(input);
}

/// -Determine the ASCII code for the current character of the string.
/// -Increase the current value by the ASCII code you just determined.
/// -Set the current value to itself multiplied by 17.
/// -Set the current value to the remainder of dividing itself by 256.
fn hash(string: []const u8) u32 {
    var value: u32 = 0;
    for (string) |c|
        value = @rem((value + c) * 17, 256);

    return value;
}

var boxes: []std.ArrayList(Instruction) = undefined;

pub fn initBoxes(alloc: Allocator) !void {
    boxes = try alloc.alloc(Array(Instruction), 256);
    for (boxes) |*b|
        b.* = Array(Instruction).init(alloc);
}
pub fn deinitBoxes(alloc: Allocator) void {
    for (boxes) |*b|
        b.*.deinit();
    alloc.free(boxes);
}

const Instruction = struct {
    label: []const u8,
    lens: ?u4,
    op: enum { remove, insert },
    h: u32,
    pub fn parse(string: []const u8) !Instruction {
        const splitLoc = std.mem.indexOfAny(u8, string, "-=");
        if (splitLoc == null) return error.NoInstruction;

        return .{
            .label = string[0..splitLoc.?],
            .lens = if (string[splitLoc.?] == '=') try atoi(u4, string[splitLoc.? + 1 ..]) else null,
            .op = if (string[splitLoc.?] == '=') .insert else .remove,
            .h = hash(string[0..splitLoc.?]),
        };
    }
};

fn doInstruction(insString: []const u8) !void {
    const ins = try Instruction.parse(insString);
    var box = &boxes[ins.h];
    std.debug.print("doing {any}\n", .{ins});

    switch (ins.op) {
        .remove => {
            for (box.items, 0..) |l, i| {
                if (std.mem.eql(u8, ins.label, l.label)) {
                    std.debug.print("removing {any}", .{l});
                    _ = box.orderedRemove(i);
                }
            }
        },
        .insert => {
            var found: usize = 0;
            for (box.items) |*l| {
                if (std.mem.eql(u8, ins.label, l.label)) {
                    std.debug.print("found a lens {}\n", .{l.h});
                    l.lens = ins.lens;
                    found += 1;
                }
            }
            if (found == 0)
                try box.append(ins);
        },
    }
}

pub fn runTape(input: []const u8) !u32 {
    var iter = std.mem.tokenize(u8, input, ",");
    var sum: u32 = 0;
    while (iter.next()) |ins|
        try doInstruction(ins);

    for (boxes, 0..) |b, i| {
        for (b.items, 0..) |l, j| {
            // One plus the box number of the lens in question.
            // The slot number of the lens within the box: 1 for the first lens, 2 for the second lens, and so on.
            // The focal length of the lens.
            const power: u32 = @as(u32, (@intCast((i + 1) * (j + 1)))) * l.lens.?;
            sum += power;
        }
    }
    return sum;
}

test "hash" {
    try testing.expectEqual(hash("rn=1"), 30);
    try testing.expectEqual(hash("cm-"), 253);
    try testing.expectEqual(hash("qp=3"), 97);
    try testing.expectEqual(hash("cm=2"), 47);
    try testing.expectEqual(hash("qp-"), 14);
    try testing.expectEqual(hash("pc=4"), 180);
    try testing.expectEqual(hash("ot=9"), 9);
    try testing.expectEqual(hash("ab=5"), 197);
    try testing.expectEqual(hash("pc-"), 48);
    try testing.expectEqual(hash("pc=6"), 214);
    try testing.expectEqual(hash("ot=7"), 231);
}

test "inst" {
    try initBoxes(testing.allocator);
    defer deinitBoxes(testing.allocator);

    // std.debug.print("{any}\n", .{try Instruction.parse("rn=1")});
    try doInstruction("rn=1");
    std.debug.print("{s}\n", .{boxes[0].items[0].label});
    try testing.expectEqualDeep(boxes[0].items[0].label, "rn");
    try doInstruction("cm-");
    try testing.expectEqualDeep(boxes[0].items[0].label, "rn");
    try doInstruction("qp=3");
    try testing.expectEqualDeep(boxes[1].items[0].label, "qp");
}

test "tape" {
    try initBoxes(testing.allocator);
    defer deinitBoxes(testing.allocator);
    const tape = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";
    try testing.expectEqual(try runTape(tape), 145);
}
