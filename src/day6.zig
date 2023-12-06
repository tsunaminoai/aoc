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
const Race = struct { time: i32 = 0, dist: i32 = 0 };
const eql = std.mem.eql;

pub fn day6(writer: anytype, alloc: std.mem.Allocator) !void {
    const ret = try part1(INPUT, alloc);
    try writer.print("Ways to beat elves: {}\n", .{ret});
}

pub fn part1(input: []const u8, alloc: std.mem.Allocator) !i32 {
    var ret: i32 = 1;
    const races = try tokenizeInput(input, alloc);
    defer races.deinit();
    for (races.items) |r| {
        const result = try getRacePerms(r, alloc);
        defer result.deinit();
        ret *= @intCast(result.items.len);
    }
    return ret;
}

pub fn tokenizeInput(input: []const u8, alloc: std.mem.Allocator) !RaceList {
    var output = RaceList.init(alloc);
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
            1 => try output.append(Race{ .time = try atoi(i32, token) }),
            2 => {
                output.items[idx].dist = try atoi(i32, token);
                idx += 1;
            },
            else => unreachable,
        }
    }
    return output;
}

const Strat = struct {
    holdTime: i32 = 0,
    distanceTraveld: i32 = 0,
};
const StratList = std.ArrayList(Strat);

pub fn getRacePerms(race: Race, alloc: std.mem.Allocator) !StratList {
    var holdTime: i32 = 0;
    const raceTime = race.time;
    var output = StratList.init(alloc);
    while (holdTime < raceTime) : (holdTime += 1) {
        const velocity: i32 = holdTime;
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
}
