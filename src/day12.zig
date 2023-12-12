const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const Array = std.ArrayList;

pub usingnamespace @import("root.zig");

pub fn day(writer: anytype, alloc: Allocator) !void {
    _ = alloc;
    _ = writer;
}
const State = enum {
    working,
    broken,
    unknown,
    pub fn fromChar(c: u8) State {
        return switch (c) {
            '.' => .working,
            '#' => .broken,
            '?' => .unknown,
            else => undefined,
        };
    }
};
const Onsen = struct {
    index: usize,
    state: State,
};
const Group = struct {
    index: usize,
    state: State,
    len: usize,
    checked: bool = false,
};
const Springs = struct {
    onsens: Array(Onsen) = undefined,
    groups: Array(Group) = undefined,
    dmgReport: Array(u32) = undefined,
    pub fn deinit(self: *Springs) void {
        self.onsens.deinit();
        self.groups.deinit();
        self.dmgReport.deinit();
    }
};
pub fn parseLine(input: []const u8, alloc: Allocator) !Springs {
    var springs = Springs{
        .onsens = Array(Onsen).init(alloc),
        .dmgReport = Array(u32).init(alloc),
        .groups = Array(Group).init(alloc),
    };
    var iter = std.mem.split(u8, input, " ");
    const onsens = iter.next().?;
    const damage = iter.rest();

    var currentState = State.fromChar(onsens[0]);
    var group = Group{
        .index = 0,
        .state = currentState,
        .len = 1,
    };
    var len: usize = 0;

    for (onsens, 0..) |c, i| {
        const cState = State.fromChar(c);
        if (cState != currentState) {
            currentState = cState;
            group.len = len;
            try springs.groups.append(group);

            group = .{
                .index = i,
                .state = currentState,
                .len = 1,
            };
            len = 0;
        }
        len += 1;
    }
    group.len = len;
    try springs.groups.append(group);

    var dmgIter = std.mem.split(u8, damage, ",");
    while (dmgIter.next()) |d|
        try springs.dmgReport.append(try std.fmt.parseInt(u8, @ptrCast(d), 10));

    return springs;
}

// #.#.### 1,1,3
// ???.### 1,1,3
pub fn findUnknowns(springs: Springs) !u32 {
    var iter = std.mem.tokenize(u32, springs.dmgReport.items, &[_]u32{0});
    while (iter.next()) |*r| {
        const nextGroup = blk: for (springs.groups.items) |g| {
            if (!g.checked) break :blk g;
        } else undefined;
        var sum: u32 = r.ptr[0];

        while (sum < nextGroup.len) {
            const row = iter.next();
            if (row) |i|
                sum += i[0]
            else
                break;
        }
        std.debug.print("{}\n", .{sum});
    }

    return 0;
}

test "line" {
    var w = try parseLine("???.### 1,1,3", testing.allocator);
    defer w.deinit();
    _ = try findUnknowns(w);

    for (w.groups.items) |g|
        std.debug.print("{any}\n", .{g});

    try testing.expectEqual(w.groups.items.len, 3);
}

// .#...#....###. 1,1,3
// .??..??...?##. 1,1,3
// .#.###.#.###### 1,3,1,6
// ?#?#?#?#?#?#?#? 1,3,1,6
// ####.#...#... 4,1,1
// ????.#...#... 4,1,1
// #....######..#####. 1,6,5
// ????.######..#####. 1,6,5
// .###.##....# 3,2,1
// ?###???????? 3,2,1
