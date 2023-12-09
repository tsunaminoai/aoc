/// so I know this method /should/ work, but I'm ending up with segfaults and not
/// enough time in my life to solve that.
const std = @import("std");
const atoi = @import("root.zig").atoi2;

pub fn day7(writer: anytype, alloc: std.mem.Allocator) !void {
    var file = try std.fs.cwd().openFile("inputs/day7.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(alloc, 100_000);
    try writer.print("Total winnings: {}\n", .{try part1(content, alloc)});
}

const Cards = "AKQJT98765432";

const Results = enum(i8) {
    None = -1,
    HighCard = 0,
    OnePair,
    TwoPair,
    ThreeOfAKind,
    FourOfAKind,
    FullHouse,
    FiveOfAKind,
    pub fn isLessThan(self: Results, other: Results) bool {
        return @intFromEnum(self) < @intFromEnum(other);
    }
};

const Card = struct {
    tag: u8,
    count: i32 = 1,
    value: u8,
};
fn cardSort(T: std.ArrayList(Card), lhs: Card, rhs: Card) bool {
    _ = T;
    return lhs.value < rhs.value;
}
const Hand = struct {
    cards: std.ArrayList(Card),
    score: u32 = 0,
    rank: u32 = 0,
    bid: u32 = 0,
    result: Results = .None,
    string: []const u8,
    alloc: std.mem.Allocator,

    const Self = @This();
    // pub fn sort(self: *Self) !void {
    //     std.mem.sort(Card, self.cards.items, self.cards, cardSort);
    // }
    pub fn init(string: []const u8, alloc: std.mem.Allocator) !Self {
        var cards = std.ArrayList(Card).init(alloc);

        for (string) |c| {
            const needle = [1]u8{c};
            try cards.append(.{ .tag = c, .value = @intCast(std.mem.indexOf(u8, Cards, &needle).?) });
        }

        var ret = Self{
            .cards = cards,
            .alloc = alloc,
            .string = string,
        };
        // try ret.sort();
        ret.result = try ret.getResult();
        return ret;
    }

    pub fn isLessThan(self: Self, other: Hand) bool {
        if (self.result.isLessThan(other.result))
            return true;
        if (self.result == other.result) {
            for (self.cards.items, 0..) |c, i| {
                if (c.value < other.cards.items[i].value)
                    return true;
            }
            return false;
        }
        return false;
    }

    pub fn getResult(self: *Self) !Results {
        var res: Results = .None;
        var ignoreList = std.ArrayList(u8).init(self.alloc);
        defer ignoreList.deinit();

        var list = try self.cards.clone();
        defer list.deinit();

        std.mem.sort(Card, list.items, list, cardSort);

        var last: u8 = self.cards.items[0].value;
        var count: u8 = 0;
        for (self.cards.items, 0..) |c, i| {
            if (c.value != last) {
                last = c.value;
                count = 1;
                continue;
            } else {
                count += 1;
            }

            const tmp: Results = switch (count) {
                1 => .HighCard,
                2 => .OnePair,
                3 => .ThreeOfAKind,
                4 => .FourOfAKind,
                5 => .FiveOfAKind,
                else => .None,
            };
            if (res == .OnePair and tmp == .OnePair) {
                res = .TwoPair;
            } else if (i == 4 and (res == .OnePair and tmp == .ThreeOfAKind) or (tmp == .OnePair and res == .ThreeOfAKind)) {
                res = .FullHouse;
            } else if (res.isLessThan(tmp))
                res = tmp;
        }

        return res;
    }

    pub fn deinit(self: *Self) void {
        self.cards.deinit();
    }
};

pub fn sortFn(T: std.ArrayList(Hand), a: Hand, b: Hand) bool {
    _ = T;
    return a.isLessThan(b);
}

pub fn parseHands(input: []const u8, alloc: std.mem.Allocator) !std.ArrayList(Hand) {
    var hands = std.ArrayList(Hand).init(alloc);

    var tokens = std.mem.tokenizeAny(u8, input, " \n");
    while (tokens.next()) |token| {
        var hand = try Hand.init(token, alloc);
        const bid = tokens.next();
        hand.bid = try atoi(u32, bid.?);
        _ = try hand.getResult();
        try hands.append(hand);
    }
    //std.mem.sort(Hand, hands.items, hands, sortFn);
    return hands;
}

pub fn part1(input: []const u8, alloc: std.mem.Allocator) !u32 {
    var hands = try parseHands(input, alloc);
    defer {
        for (hands.items) |*h|
            h.deinit();
        hands.deinit();
    }

    var total: u32 = 0;
    for (hands.items, 0..) |h, i| {
        const add = @as(u32, @intCast(i + 1)) * h.bid;
        total += add;
        if (i % 100 == 0) {
            std.debug.print(
                "Rank: {}, hand: {s}, bid: {}, result: {s}, adding: {}, total: {}\n",
                .{ i, h.string, h.bid, @tagName(h.result), add, total },
            );
        }
    }
    return total;
}

test "day 7" {
    const INPUT =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;
    const p1 = try part1(INPUT, std.testing.allocator);
    try std.testing.expectEqual(p1, 6440);

    //250254244
    // var file = try std.fs.cwd().openFile("inputs/day7.txt", .{});
    // defer file.close();

    // const content = try file.readToEndAlloc(std.testing.allocator, 100_000);
    // defer std.testing.allocator.free(content);
    // const p2 = try part1(content, std.testing.allocator);
    // try std.testing.expectEqual(p2, 250254244);
}

test "High card" {
    var h = try Hand.init("32AKJ", std.testing.allocator);
    defer h.deinit();
    try std.testing.expectEqual(h.getResult(), .HighCard);
}

test "one pair" {
    var h = try Hand.init("33K4J", std.testing.allocator);
    defer h.deinit();
    try std.testing.expectEqual(h.getResult(), .OnePair);
}

test "two pair" {
    var h = try Hand.init("33KJJ", std.testing.allocator);
    defer h.deinit();
    try std.testing.expectEqual(h.getResult(), .TwoPair);
}
test "3 of a kind" {
    var h = try Hand.init("333KJ", std.testing.allocator);
    defer h.deinit();
    try std.testing.expectEqual(h.getResult(), .ThreeOfAKind);
}
test "bob saget" {
    var h = try Hand.init("333KK", std.testing.allocator);
    defer h.deinit();
    try std.testing.expectEqual(h.getResult(), .FullHouse);
}
test "4 of a kind" {
    var h = try Hand.init("3333J", std.testing.allocator);
    defer h.deinit();
    try std.testing.expectEqual(h.getResult(), .FourOfAKind);
}
test "5 of a kind" {
    var h = try Hand.init("JJJJJ", std.testing.allocator);
    defer h.deinit();
    try std.testing.expectEqual(h.getResult(), .FiveOfAKind);
}

test "hand" {
    var h = try Hand.init("32T3K", std.testing.allocator);
    defer h.deinit();

    try std.testing.expectEqual(h.cards.items[0].tag, '3');
}

test "parse" {
    const INPUT =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;
    const hands = try parseHands(INPUT, std.testing.allocator);
    defer {
        for (hands.items) |*h|
            h.deinit();
        hands.deinit();
    }
}
