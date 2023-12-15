/// Day 2
/// ------
/// Sum of game IDs that are possible: 1853
/// Sum of possible game powers: 72706
///
/// ________________________________________________________
/// Executed in  100.12 millis    fish           external
///    usr time    3.58 millis   32.00 micros    3.55 millis
///    sys time    8.09 millis  417.00 micros    7.68 millis
///
const std = @import("std");
const atoi = @import("root.zig").stringDigitsToNumber;

/// day 2
pub fn day(writer: anytype, alloc: std.mem.Allocator) !void {
    const limits = CubeCounts{ .blue = 14, .red = 12, .green = 13 };

    var inputFile = try std.fs.cwd().openFile("inputs/day2.txt", .{});
    defer inputFile.close();

    var reader = inputFile.reader();
    const buffer = try alloc.alloc(u8, 1000);
    defer alloc.free(buffer);

    var idSum: u32 = 0;
    var powerSum: u32 = 0;

    while (true) {
        const line = try reader.readUntilDelimiterOrEof(buffer, '\n');
        if (line) |l| {
            var gameCount = try parseGame(l);
            powerSum += gameCount.getPower();
            if (gameCount.isValid(limits))
                idSum += gameCount.gameId;
        } else break;
    }
    try writer.print("Sum of game IDs that are possible: {}\n", .{idSum});
    try writer.print("Sum of possible game powers: {}\n", .{powerSum});
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
    fn getPower(self: *CubeCounts) u32 {
        return self.red * self.green * self.blue;
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
    try std.testing.expectEqual(countCubes("3 blue, 4 red"), .{ .blue = 3, .red = 4 });
    try std.testing.expectEqual(countCubes("1 red, 2 green, 6 blue"), .{ .blue = 6, .red = 1, .green = 2 });
    try std.testing.expectEqual(countCubes("2 green"), .{ .green = 2 });
}

test "gameid" {
    try std.testing.expectEqual(getGameId("Game 5"), 5);
    try std.testing.expectEqual(getGameId("Game 15"), 15);
}

//part 2

// As you continue your walk, the Elf poses a second question: in each game
// you played, what is the fewest number of cubes of each color that could
// have been in the bag to make the game possible?
//
// Again consider the example games from earlier:
//
// Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
// Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
// Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
// Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
// Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
//
// In game 1, the game could have been played with as few as 4 red, 2 green,
// and 6 blue cubes. If any color had even one fewer cube, the game would
// have been impossible.
// Game 2 could have been played with a minimum of 1 red, 3 green, and 4 blue
// cubes.
// Game 3 must have been played with at least 20 red, 13 green, and 6 blue
// cubes.
// Game 4 required at least 14 red, 3 green, and 15 blue cubes.
// Game 5 needed no fewer than 6 red, 3 green, and 2 blue cubes in the bag.
// The power of a set of cubes is equal to the numbers of red, green, and
// blue cubes multiplied together. The power of the minimum set of cubes in
// game 1 is 48. In games 2-5 it was 12, 1560, 630, and 36, respectively.
// Adding up these five powers produces the sum 2286.
//
// For each game, find the minimum set of cubes that must have been present.
// What is the sum of the power of these sets?
test "power" {
    var t = CubeCounts{ .blue = 6, .red = 4, .green = 2 };
    try std.testing.expectEqual(t.getPower(), 48);
    t = .{ .blue = 4, .red = 1, .green = 3 };
    try std.testing.expectEqual(t.getPower(), 12);
    t = .{ .blue = 6, .red = 20, .green = 13 };
    try std.testing.expectEqual(t.getPower(), 1560);
    t = .{ .blue = 15, .red = 14, .green = 3 };
    try std.testing.expectEqual(t.getPower(), 630);
    t = .{ .blue = 2, .red = 6, .green = 3 };
    try std.testing.expectEqual(t.getPower(), 36);
}
