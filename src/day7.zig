const std = @import("std");
const atoi = @import("root.zig").atoi2;

pub fn day7(writer: anytype, alloc: std.mem.Allocator) !void {
    var file = try std.fs.cwd().openFile("inputs/day7.txt", .{});
    defer file.close();

    const content = try file.readToEndAlloc(alloc, 100_000);
    try writer.print("Total winnings: {}\n", .{try part1(content, alloc)});
}

const CardTag = enum(u8) {
    c2 = 2,
    c3,
    c4,
    c5,
    c6,
    c7,
    c8,
    c9,
    cT,
    cJ,
    cK,
    cQ,
    cA,
    pub fn toInt(self: @This()) u8 {
        return @intFromEnum(self);
    }
    pub fn fromChar(char: u8) @This() {
        return switch (char) {
            '2' => .c2,
            '3' => .c3,
            '4' => .c4,
            '5' => .c5,
            '6' => .c6,
            '7' => .c7,
            '8' => .c8,
            '9' => .c9,
            'T' => .cT,
            'J' => .cJ,
            'Q' => .cQ,
            'K' => .cK,
            'A' => .cA,
            else => unreachable,
        };
    }
};

const Results = enum(u8) {
    None,
    HighCard,
    OnePair,
    TwoPair,
    ThreeOfAKind,
    FullHouse,
    FourOfAKind,
    FiveOfAKind,
    pub fn isLessThan(self: Results, other: Results) bool {
        return @intFromEnum(self) < @intFromEnum(other);
    }
};

const Card = struct {
    tag: CardTag,
    count: u32 = 0,
};
fn cardSort(T: std.StringArrayHashMap(Card), lhs: Card, rhs: Card) bool {
    _ = T;
    return lhs.tag.toInt() < rhs.tag.toInt();
}
const Hand = struct {
    cards: std.StringArrayHashMap(Card) = undefined,
    score: u32 = 0,
    rank: u32 = 0,
    value: u32 = 0,
    bid: u32 = 0,
    result: Results = .None,
    string: []const u8,
    alloc: std.mem.Allocator,

    const Self = @This();
    // pub fn sort(self: *Self) !void {
    //     std.mem.sort(Card, self.cards.items, self.cards, cardSort);
    // }
    pub fn init(string: []const u8, alloc: std.mem.Allocator) !Self {
        var cards = std.StringArrayHashMap(Card).init(alloc);
        for (string, 0..) |c, i| {
            const card = try cards.getOrPut(string[i .. i + 1]);
            if (!card.found_existing)
                card.value_ptr.* = Card{ .tag = CardTag.fromChar(c) };
            card.value_ptr.*.count += 1;
        }

        var ret = Self{
            .cards = cards,
            .alloc = alloc,
            .string = string,
        };
        // try ret.sort();
        _ = ret.getValue();
        ret.result = ret.getResult();
        return ret;
    }
    pub fn getValue(self: *Self) u32 {
        if (self.value == 0) {
            var sum: u32 = 0;
            for (self.cards.values()) |card|
                sum += card.tag.toInt() * card.count;
            self.value = sum;
        }

        return self.value;
    }

    pub fn isLessThan(self: Self, other: Hand) bool {
        // std.debug.print(
        //     "Called with \na: {s} => {s}\nb: {s} => {s} {}\n",
        //     .{
        //         self.string,
        //         @tagName(self.result),
        //         other.string,
        //         @tagName(other.result),
        //         self.result.isLessThan(other.result),
        //     },
        // );
        if (self.result.isLessThan(other.result))
            return true;
        if (self.result == other.result) {
            for (0..5) |i| {
                // std.debug.print("for {} ", .{i});
                if (self.string[i] == other.string[i])
                    continue;
                const s = CardTag.fromChar(self.string[i]);
                const o = CardTag.fromChar(other.string[i]);
                // std.debug.print("Checking {s} {s}\n", .{ @tagName(s), @tagName(o) });
                return s.toInt() < o.toInt();
            }
        }
        return false;
    }

    pub fn getResult(self: *Self) Results {
        var res: Results = .None;
        for (self.cards.values()) |card| {
            var tmp: Results = switch (card.count) {
                1 => .HighCard,
                2 => .OnePair,
                3 => .ThreeOfAKind,
                4 => .FourOfAKind,
                5 => .FiveOfAKind,
                else => unreachable,
            };
            if (res == .OnePair and tmp == .OnePair)
                tmp = .TwoPair;
            if (res == .OnePair and tmp == .ThreeOfAKind or tmp == .OnePair and res == .ThreeOfAKind)
                tmp = .FullHouse;
            if (res.isLessThan(tmp))
                res = tmp;
            // std.debug.print("result: {s}, tmp: {s}\n", .{ @tagName(res), @tagName(tmp) });
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
        _ = hand.getResult();
        try hands.append(hand);
    }
    std.mem.sort(Hand, hands.items, hands, sortFn);
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
    for (hands.items, 1..) |h, i| {
        total += @as(u32, @intCast(i)) * h.bid;
        std.debug.print(
            "Rank: {}, hand: {s}, bid: {}, total: {}\n",
            .{ i, h.string, h.bid, total },
        );
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
}

test "hand" {
    var h = try Hand.init("32T3K", std.testing.allocator);
    defer h.deinit();

    var h2 = try Hand.init("KK677", std.testing.allocator);
    defer h2.deinit();
    var h3 = try Hand.init("KTJJT", std.testing.allocator);
    defer h3.deinit();
    var h4 = try Hand.init("KKKQQ", std.testing.allocator);
    defer h4.deinit();

    try std.testing.expectEqual(h.cards.get("2").?.tag, .c2);
    try std.testing.expectEqual(h.cards.get("3").?.count, 2);
    try std.testing.expectEqual(h.getValue(), 30);
    try std.testing.expect(Results.FullHouse.isLessThan(Results.FourOfAKind));
    try std.testing.expectEqual(h.getResult(), .OnePair);
    try std.testing.expectEqual(h2.getResult(), .TwoPair);
    try std.testing.expectEqual(h3.getResult(), .TwoPair);
    try std.testing.expectEqual(h4.getResult(), .FullHouse);
    try std.testing.expect(h3.isLessThan(h2));
}
