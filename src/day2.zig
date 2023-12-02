/// --- Day 2: Cube Conundrum ---
/// You're launched high into the atmosphere! The apex of your trajectory just
/// barely reaches the surface of a large island floating in the sky. You gently
/// land in a fluffy pile of leaves. It's quite cold, but you don't see much snow.
/// An Elf runs over to greet you.
///
/// The Elf explains that you've arrived at Snow Island and apologizes for the
/// lack of snow. He'll be happy to explain the situation, but it's a bit of a
/// walk, so you have some time. They don't get many visitors up here; would you
/// like to play a game in the meantime?
///
/// As you walk, the Elf shows you a small bag and some cubes which are either
/// red, green, or blue. Each time you play this game, he will hide a secret
/// number of cubes of each color in the bag, and your goal is to figure out
/// information about the number of cubes.
///
/// To get information, once a bag has been loaded with cubes, the Elf will
/// reach into the bag, grab a handful of random cubes, show them to you, and
/// then put them back in the bag. He'll do this a few times per game.
///
/// You play several games and record the information from each game (your
/// puzzle input). Each game is listed with its ID number (like the 11 in
/// Game 11: ...) followed by a semicolon-separated list of subsets of cubes
/// that were revealed from the bag (like 3 red, 5 green, 4 blue).
///
/// For example, the record of a few games might look like this:
///
/// Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
/// Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
/// Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
/// Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
/// Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
///
/// In game 1, three sets of cubes are revealed from the bag (and then put
/// back again). The first set is 3 blue cubes and 4 red cubes; the second set
/// is 1 red cube, 2 green cubes, and 6 blue cubes; the third set is only 2
/// green cubes.
///
/// The Elf would first like to know which games would have been possible if
/// the bag contained only 12 red cubes, 13 green cubes, and 14 blue cubes?
///
/// In the example above, games 1, 2, and 5 would have been possible if the bag
/// had been loaded with that configuration. However, game 3 would have been
/// impossible because at one point the Elf showed you 20 red cubes at once;
/// similarly, game 4 would also have been impossible because the Elf showed
/// you 15 blue cubes at once. If you add up the IDs of the games that would
/// have been possible, you get 8.
///
/// Determine which games would have been possible if the bag had been loaded
/// with only 12 red cubes, 13 green cubes, and 14 blue cubes. What is the sum
/// of the IDs of those games?
const std = @import("std");
const atoi = @import("root.zig").stringDigitsToNumber;

pub fn day2(writer: anytype, alloc: std.mem.Allocator) !void {
    const limits = CubeCounts{ .blue = 14, .red = 12, .green = 13 };

    var inputFile = try std.fs.cwd().openFile("inputs/day2.txt", .{});
    defer inputFile.close();

    var reader = inputFile.reader();
    const buffer = try alloc.alloc(u8, 1000);
    defer alloc.free(buffer);

    var ret: u32 = 0;

    while (true) {
        const line = try reader.readUntilDelimiterOrEof(buffer, '\n');
        if (line) |l| {
            var gameCount = try parseGame(l);
            if (gameCount.isValid(limits))
                ret += gameCount.gameId;
        } else break;
    }
    try writer.print("Sum of game IDs that are possible: {}\n", .{ret});
}

const CubeCounts = struct {
    gameId: u32 = 0,
    blue: u32 = 0,
    red: u32 = 0,
    green: u32 = 0,
    pub fn add(self: *CubeCounts, other: CubeCounts) void {
        self.blue += other.blue;
        self.red += other.red;
        self.green += other.green;
    }
    pub fn max(self: *CubeCounts, other: CubeCounts) void {
        if (self.blue < other.blue) self.blue = other.blue;
        if (self.red < other.red) self.red = other.red;
        if (self.green < other.green) self.green = other.green;
    }
    pub fn isValid(self: *CubeCounts, limits: CubeCounts) bool {
        return self.blue <= limits.blue and self.red <= limits.red and self.green <= limits.green;
    }
};

fn parseGame(string: []const u8) !CubeCounts {
    var counts = CubeCounts{};

    var gameIter = std.mem.splitSequence(u8, string, ":");
    const game = gameIter.first();
    counts.gameId = try getGameId(game);

    counts.max(try parseRounds(gameIter.rest()));
    return counts;
}

fn parseRounds(string: []const u8) !CubeCounts {
    var counts = CubeCounts{};
    var roundIter = std.mem.splitSequence(u8, string, ";");
    while (roundIter.next()) |r|
        counts.max(try countCubes(r));
    return counts;
}

fn getGameId(string: []const u8) !u32 {
    var idIter = std.mem.splitSequence(u8, string, " ");
    _ = idIter.next();
    const idStr = if (idIter.peek()) |next| blk: {
        break :blk next;
    } else return error.BadString;

    return try atoi(idStr);
}

fn countCubes(string: []const u8) !CubeCounts {
    // 1 red, 2 green, 6 blue
    var counts = CubeCounts{};
    var colorIter = std.mem.splitSequence(u8, string, ",");
    while (colorIter.next()) |color| {
        var spaceIter = std.mem.splitSequence(u8, color, " ");
        var countStr = spaceIter.next();
        if (countStr == null)
            return error.BadString;
        if (countStr.?.len == 0)
            countStr = spaceIter.next();

        const colorStr = spaceIter.rest();
        if (std.mem.eql(u8, colorStr, "blue")) {
            counts.blue += try atoi(countStr.?);
        } else if (std.mem.eql(u8, colorStr, "red")) {
            counts.red += try atoi(countStr.?);
        } else if (std.mem.eql(u8, colorStr, "green")) {
            counts.green += try atoi(countStr.?);
        } else {
            std.debug.print(
                "Parse error: color: '{s}', countstr: {s}, colorstr: {s}\n",
                .{ color, countStr.?, colorStr },
            );
            return error.BadString;
        }
    }
    return counts;
}

test "day2" {
    try std.testing.expectEqual(
        try parseGame("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green"),
        .{ .gameId = 1, .blue = 6, .red = 4, .green = 2 },
    );
    try std.testing.expectEqual(
        try parseGame("Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue"),
        .{ .gameId = 2, .blue = 4, .red = 1, .green = 3 },
    );
    try std.testing.expectEqual(
        try parseGame("Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red"),
        .{ .gameId = 3, .blue = 6, .red = 20, .green = 13 },
    );
    try std.testing.expectEqual(
        try parseGame("Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red"),
        .{ .gameId = 4, .blue = 15, .red = 14, .green = 3 },
    );
    try std.testing.expectEqual(
        try parseGame("Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green"),
        .{ .gameId = 5, .blue = 2, .red = 6, .green = 3 },
    );
}

test "cube counts" {
    const test1 = "3 blue, 4 red";
    const test2 = "1 red, 2 green, 6 blue";
    _ = test2;
    const test3 = "2 green";
    _ = test3;
    try std.testing.expectEqual(countCubes(test1), .{ .blue = 3, .red = 4 });
}

test "gameid" {
    try std.testing.expectEqual(getGameId("Game 5"), 5);
    try std.testing.expectEqual(getGameId("Game 15"), 15);
}
