/// The almanac (your puzzle input) lists all of the seeds that need to be
/// planted. It also lists what type of soil to use with each kind of seed,
/// what type of fertilizer to use with each kind of soil, what type of water
/// to use with each kind of fertilizer, and so on. Every type of seed, soil,
/// fertilizer and so on is identified with a number, but numbers are reused
/// by each category - that is, soil 123 and fertilizer 123 aren't necessarily
/// related to each other.
/// seeds: 79 14 55 13
///
/// seed-to-soil map:
/// 50 98 2
/// 52 50 48
///
/// soil-to-fertilizer map:
/// 0 15 37
/// 37 52 2
/// 39 0 15
///
/// fertilizer-to-water map:
/// 49 53 8
/// 0 11 42
/// 42 0 7
/// 57 7 4
///
/// water-to-light map:
/// 88 18 7
/// 18 25 70
///
/// light-to-temperature map:
/// 45 77 23
/// 81 45 19
/// 68 64 13
///
/// temperature-to-humidity map:
/// 0 69 1
/// 1 0 69
///
/// humidity-to-location map:
/// 60 56 37
/// 56 93 4
///
/// The almanac starts by listing which seeds need to be planted: seeds 79, 14, 55, and 13.
/// The rest of the almanac contains a list of maps which describe how to convert numbers from a source category into numbers in a destination category. That is, the section that starts with seed-to-soil map: describes how to convert a seed number (the source) to a soil number (the destination). This lets the gardener and his team know which soil to use with which seeds, which water to use with which fertilizer, and so on.
///
/// Rather than list every source number and its corresponding destination number one by one, the maps describe entire ranges of numbers that can be converted. Each line within a map contains three numbers: the destination range start, the source range start, and the range length.
///
/// Consider again the example seed-to-soil map:
///
/// 50 98 2
/// 52 50 48
/// The first line has a destination range start of 50, a source range start of 98, and a range length of 2. This line means that the source range starts at 98 and contains two values: 98 and 99. The destination range is the same length, but it starts at 50, so its two values are 50 and 51. With this information, you know that seed number 98 corresponds to soil number 50 and that seed number 99 corresponds to soil number 51.
///
/// The second line means that the source range starts at 50 and contains 48 values: 50, 51, ..., 96, 97. This corresponds to a destination range starting at 52 and also containing 48 values: 52, 53, ..., 98, 99. So, seed number 53 corresponds to soil number 55.
///
/// Any source numbers that aren't mapped correspond to the same destination number. So, seed number 10 corresponds to soil number 10.
///
/// So, the entire list of seed numbers and their corresponding soil numbers looks like this:
///
/// seed  soil
/// 0     0
/// 1     1
/// ...   ...
/// 48    48
/// 49    49
/// 50    52
/// 51    53
/// ...   ...
/// 96    98
/// 97    99
/// 98    50
/// 99    51
/// With this map, you can look up the soil number required for each initial seed number:
///
/// Seed number 79 corresponds to soil number 81.
/// Seed number 14 corresponds to soil number 14.
/// Seed number 55 corresponds to soil number 57.
/// Seed number 13 corresponds to soil number 13.
/// The gardener and his team want to get started as soon as possible, so they'd like to know the closest location that needs a seed. Using these maps, find the lowest location number that corresponds to any of the initial seeds. To do this, you'll need to convert each seed number through other categories until you can find its corresponding location number. In this example, the corresponding types are:
///
/// Seed 79, soil 81, fertilizer 81, water 81, light 74, temperature 78, humidity 78, location 82.
/// Seed 14, soil 14, fertilizer 53, water 49, light 42, temperature 42, humidity 43, location 43.
/// Seed 55, soil 57, fertilizer 57, water 53, light 46, temperature 82, humidity 82, location 86.
/// Seed 13, soil 13, fertilizer 52, water 41, light 34, temperature 34, humidity 35, location 35.
/// So, the lowest location number in this example is 35.
///
/// What is the lowest location number that corresponds to any of the initial seed numbers?
const std = @import("std");
const atoi = @import("root.zig").atoi2;

pub fn day5(writer: anytype, alloc: std.mem.Allocator) !void {
    _ = alloc;
    _ = writer;
}

/// Rather than list every source number and its corresponding destination number one by one, the maps describe entire ranges of numbers that can be converted. Each line within a map contains three numbers: the destination range start, the source range start, and the range length.
/// The first line has a destination range start of 50, a source range start of 98, and a range length of 2. This line means that the source range starts at 98 and contains two values: 98 and 99. The destination range is the same length, but it starts at 50, so its two values are 50 and 51. With this information, you know that seed number 98 corresponds to soil number 50 and that seed number 99 corresponds to soil number 51.
/// The second line means that the source range starts at 50 and contains 48 values: 50, 51, ..., 96, 97. This corresponds to a destination range starting at 52 and also containing 48 values: 52, 53, ..., 98, 99. So, seed number 53 corresponds to soil number 55.
fn maps() void {}

const Seed = u8;
const Soil = u8;
const Fertilizer = u8;
const Water = u8;
const Light = u8;
const Temperature = u8;
const Humidity = u8;
const Location = u8;

test "day5 part 1" {
    const input =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;
    _ = input;
    // var output: *std.StringArrayHashMap(MapHashMap) = try decompose(input, std.testing.allocator);
    // try output.hasPath();
}

const PossibleStates = enum {
    seeds,
    seedToSoil,
    soilToFertilizer,
    fertToWater,
    waterToLight,
    lightToTemp,
    tempToHumid,
    humidToLoc,
    const Self = @This();

    pub fn fromString(str: []const u8) ?Self {
        return stateList.get(str);
    }
    pub fn toString(self: Self) ?[]const u8 {
        for (stateList.kvs) |k|
            if (k.value == self) return k.key;
        return null;
    }
};
const stateList = std.ComptimeStringMap(PossibleStates, .{
    .{ "seeds", .seeds },
    .{ "seed-to-soil", .seedToSoil },
    .{ "soil-to-fertilizer", .soilToFertilizer },
    .{ "fertilizer-to-water", .fertToWater },
    .{ "water-to-light", .tempToHumid },
    .{ "light-to-temperature", .lightToTemp },
    .{ "temperature-to-humidity", .tempToHumid },
    .{ "humidity-to-location", .humidToLoc },
});

const CurrentState = struct {
    state: PossibleStates,

    pub fn changeState(
        self: *@This(),
        newState: PossibleStates,
        iter: ?*std.mem.TokenIterator(u8, .any),
        numIters: usize,
    ) void {
        self.state = newState;
        std.debug.print("State change: {s}\n", .{@tagName(self.state)});

        if (iter) |it| {
            for (0..numIters) |_|
                _ = it.next();
        }
    }
};
fn decompose(input: []const u8, alloc: std.mem.Allocator) !std.StringArrayHashMap(MapHashMap) {
    var t = std.mem.tokenizeAny(u8, input, " \n");

    var state = CurrentState{ .state = .seeds };

    var seeds = std.ArrayList(Seed).init(alloc);
    defer seeds.deinit();

    var mapsOfMaps = std.StringArrayHashMap(MapHashMap).init(alloc);
    defer mapsOfMaps.deinit();

    for (stateList.kvs) |s| {
        std.debug.print("making {s}\n", .{s.key});
        const v = MapHashMap.init(alloc);
        try mapsOfMaps.put(s.key, v);
    }
    defer {
        for (stateList.kvs) |s| {
            std.debug.print("killing {s}\n", .{s.key});
            mapsOfMaps.getEntry(s.key).?.value_ptr.*.deinit();
        }
    }

    var idx: usize = 0;
    while (t.next()) |tok| {
        idx += 1;
        std.debug.print("step: {} index: {} token: \"{s}\"\n", .{ idx, t.index, tok });
        if (std.mem.eql(u8, tok, "map:")) {
            continue;
        }

        if (std.mem.eql(u8, tok, "seeds:")) {
            state.changeState(.seeds, null, 0);
            continue;
        }

        if (mapsOfMaps.contains(tok)) {
            state.changeState(PossibleStates.fromString(tok).?, &t, 0);
            continue;
        }

        if (state.state == .seeds) {
            try seeds.append(try atoi(u8, tok));
            continue;
        }

        const map = try Map.init(tok, &t);
        if (mapsOfMaps.getPtr(state.state.toString().?)) |h|
            try h.put(map.destRange, map);
    }
    std.debug.print("Seeds: {any}\n", .{seeds.items});
    for (stateList.kvs) |s| {
        const v = mapsOfMaps.get(s.key).?;
        std.debug.print("{s} map:\n", .{s.key});
        for (v.values()) |m| {
            std.debug.print("{any} \n", .{m});
        }
    }
    return mapsOfMaps;
}
fn traceSeed(seed: u8, mapChain: *std.StringArrayHashMap(MapHashMap)) u8 {
    _ = mapChain;
    _ = seed;
    const res: u8 = 0;
    for (stateList.kvs) |k| {
        if (k.value == .seeds)
            continue;
    }
    return res;
}
const MapHashMap = std.AutoArrayHashMap(u8, Map);
fn hasPath(self: *std.StringArrayHashMap(MapHashMap), seed: u8) ?u8 {
    for (self.values()) |v| {
        if (v.sourceRangeStart <= seed and seed <= v.sourceRangeStart + v.rangeLen)
            return v.destinationRange;
    }
    return null;
}

const Map = packed struct {
    destRange: u8,
    srcRangeStart: u8,
    rangeLen: u8,
    const Self = @This();
    pub fn deinit(self: *Self) void {
        _ = self.*;
    }
    pub fn init(
        v1: []const u8,
        iter: *std.mem.TokenIterator(u8, .any),
    ) !Self {
        const destinationRange = v1;
        const sourceRangeStart = iter.next().?;
        const rangeLength = iter.next().?;
        std.debug.print("new map: dest: {s}, source: {s}, len: {s}\n", .{
            destinationRange,
            sourceRangeStart,
            rangeLength,
        });
        return Self{
            .destRange = try atoi(u8, destinationRange),
            .srcRangeStart = try atoi(u8, sourceRangeStart),
            .rangeLen = try atoi(u8, rangeLength),
        };
    }
    pub fn addToHashMap(self: *Self, other: *MapHashMap) !void {
        try other.put(self.destRange, self.*);
    }
};

// fn MapToMap(comptime mapType: type) type {
//     return struct {
//         array: std.ArrayList(mapType),

//         const Self = @This();
//         pub fn init(alloc: std.mem.Allocator) Self {
//             return Self{
//                 .array = std.ArrayList(mapType).init(alloc),
//             };
//         }
//         pub fn deinit(self: *Self) void {
//             self.array.deinit();
//         }
//     };
// }
