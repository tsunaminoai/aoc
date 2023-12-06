const std = @import("std");
const atoi = @import("root.zig").atoi2;

const INPUT =
    \\Time:        44     89     96     91
    \\Distance:   277   1136   1890   1768
;

const TESTINPUT =
    \\Time:      7  15   30
    \\Distance:  9  40  200
;
const RaceList = std.ArrayList(Race);
const Race = struct { time: u64 = 0, dist: u64 = 0 };
const eql = std.mem.eql;

pub fn day6(writer: anytype, alloc: std.mem.Allocator) !void {
    const ret1 = try part1(INPUT, alloc);
    const ret2 = try part2(INPUT, alloc);
    try writer.print("Ways to beat elves: {}\n", .{ret1});
    try writer.print("Actual number: {}\n", .{ret2});
}

pub fn part1(input: []const u8, alloc: std.mem.Allocator) !u64 {
    var ret: u64 = 1;
    const races = try tokenizeInput(input, alloc);
    defer races.deinit();
    for (races.items) |r| {
        const result = try getRacePerms(r, alloc);
        defer result.deinit();
        ret *= @intCast(result.items.len);
    }
    return ret;
}

pub fn part2(input: []const u8, alloc: std.mem.Allocator) !u64 {
    var newIn = try alloc.allocSentinel(u8, input.len, 0);
    defer alloc.free(newIn);

    var state: bool = false;
    var idx: usize = 0;
    for (input) |c| {
        if (std.ascii.isDigit(c))
            state = true;
        if (c == '\n')
            state = false;
        if (state and c == ' ')
            continue;
        newIn[idx] = c;
        idx += 1;
    }

    // std.debug.print("old: \n{s}\nNew:\n{s}\n", .{ input, newIn[0..idx] });
    return part1(newIn[0..idx], alloc);
}
pub fn tokenizeInput(input: []const u8, alloc: std.mem.Allocator) !RaceList {
    var output = RaceList.init(alloc);
    errdefer output.deinit();
    var tokens = std.mem.tokenizeAny(u8, input, " \n");
    var state: usize = 0;
    var idx: usize = 0;
    while (tokens.next()) |token| {
        if (eql(u8, token, "Time:")) {
            state = 1;
            continue;
        }
        if (eql(u8, token, "Distance:")) {
            state = 2;
            continue;
        }
        switch (state) {
            1 => try output.append(Race{ .time = try atoi(u64, token) }),
            2 => {
                output.items[idx].dist = try atoi(u64, token);
                idx += 1;
            },
            else => unreachable,
        }
    }
    return output;
}

const Strat = struct {
    holdTime: u64 = 0,
    distanceTraveld: u64 = 0,
};
const StratList = std.ArrayList(Strat);

pub fn getRacePerms(race: Race, alloc: std.mem.Allocator) !StratList {
    var holdTime: u64 = 0;
    const raceTime = race.time;
    var output = StratList.init(alloc);
    while (holdTime < raceTime) : (holdTime += 1) {
        const velocity: u64 = holdTime;
        const dist = (velocity * (raceTime - holdTime));
        if (dist > race.dist)
            try output.append(.{ .holdTime = holdTime, .distanceTraveld = dist });
    }
    return output;
}

const expect = std.testing.expectEqual;
test "day6" {
    const alloc = std.testing.allocator;
    var t = try tokenizeInput(TESTINPUT, alloc);
    defer t.deinit();

    try expect(t.items[0], .{ .time = 7, .dist = 9 });
    try expect(t.items[1], .{ .time = 15, .dist = 40 });
    try expect(t.items[2], .{ .time = 30, .dist = 200 });

    const race1 = try getRacePerms(t.items[0], alloc);
    defer race1.deinit();
    const race2 = try getRacePerms(t.items[1], alloc);
    defer race2.deinit();

    // for (race1.items) |r|
    //     std.debug.print("Outcome: {any}\n", .{r});
    try expect(race1.items.len, 4);
    try expect(race2.items.len, 8);

    try expect(try part1(TESTINPUT, alloc), 288);
    try expect(try part2(TESTINPUT, alloc), 71503);
}
