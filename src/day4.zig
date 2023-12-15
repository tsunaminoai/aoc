/// Day 4
/// ------
/// Sum of ticket scores: 25651
/// Number of tickets at the end: 19499881
///
/// ________________________________________________________
/// Executed in  133.28 millis    fish           external
///    usr time   17.33 millis   36.00 micros   17.29 millis
///    sys time   16.83 millis  463.00 micros   16.36 millis
///
const std = @import("std");
const atoi = @import("root.zig").stringDigitsToNumber;

pub fn day(writer: anytype, alloc: std.mem.Allocator) !void {
    var sum: u32 = 0;
    var file = try std.fs.cwd().openFile("inputs/day4.txt", .{});
    defer file.close();

    var reader = file.reader();
    var gameStack = std.ArrayList(Ticket).init(alloc);
    defer gameStack.deinit();
    var tickets = std.ArrayList(Ticket).init(alloc);
    defer tickets.deinit();

    while (try reader.readUntilDelimiterOrEofAlloc(alloc, '\n', 1000)) |line| {
        defer alloc.free(line);
        const t = try ticketScore(line, alloc);
        sum += t.score;
        try tickets.append(t);
    }
    try writer.print("Sum of ticket scores: {}\n", .{sum});

    sum = cardCount(tickets);
    try writer.print("Number of tickets at the end: {}\n", .{sum});
}

fn cardCount(tickets: std.ArrayList(Ticket)) u32 {
    var sum: u32 = 0;
    for (tickets.items, 0..) |t, currentIdx| {
        sum += t.copies;
        // std.debug.print("{}, sum: {}\n", .{ t, sum });

        for (1..t.matches + 1) |nextIdx|
            tickets.items[currentIdx + nextIdx].copies += t.copies;
    }
    return sum;
}

fn ticketScore(input: []const u8, alloc: std.mem.Allocator) !Ticket {
    _ = alloc;
    var ticketIter = std.mem.splitSequence(u8, input, ":");
    const game = ticketIter.next().?;
    const numbers = ticketIter.rest();
    var numIter = std.mem.splitSequence(u8, numbers, "|");
    const winningNumbers = numIter.next().?;
    const scratchNumbers = numIter.rest();

    var scratchIter = std.mem.tokenizeSequence(u8, scratchNumbers, " ");
    var winningIter = std.mem.tokenizeSequence(u8, winningNumbers, " ");

    var ticket = Ticket{
        .id = try getGameId(game),
        .string = input,
    };

    while (winningIter.next()) |num| {
        // std.debug.print("buffer: {s},  check token: {s}, ocurrances: {}\n", .{ scratchIter.buffer, num, std.mem.count(u8, scratchIter.buffer, num) });

        scratchIter.reset();
        while (scratchIter.next()) |check| {
            if (check.len == num.len and std.mem.eql(u8, num, check)) {
                ticket.matches += 1;
                ticket.score = if (ticket.score == 0) 1 else ticket.score * 2;
            }
        }
    }
    return ticket;
}

pub fn getGameId(input: []const u8) !u32 {
    var split = std.mem.splitSequence(u8, input, " ");
    _ = split.next().?;
    while (split.next()) |s|
        if (s.len != 0)
            return try atoi(s);
    return error.NoIDFound;
}
const Ticket = struct {
    id: u32 = 0,
    string: []const u8,
    score: u32 = 0,
    matches: u32 = 0,
    copies: u32 = 1,

    pub fn format(self: Ticket, fmt: []const u8, options: anytype, writer: anytype) !void {
        _ = options;
        _ = fmt;
        try writer.print("Card {}, score: {}, matches: {}, copies: {}", .{ self.id, self.score, self.matches, self.copies });
    }
};

test "day4" {
    const alloc = std.testing.allocator;
    var tickets = std.ArrayList(Ticket).init(alloc);
    defer tickets.deinit();

    var string: *const []const u8 = undefined;

    string = &"Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53";

    var ticket = try ticketScore(string.*, alloc);
    try std.testing.expectEqual(ticket.score, 8);
    try std.testing.expectEqual(ticket.matches, 4);
    try tickets.append(ticket);

    string = &"Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19";
    ticket = try ticketScore(string.*, alloc);
    try std.testing.expectEqual(ticket.score, 2);
    try std.testing.expectEqual(ticket.matches, 2);
    try tickets.append(ticket);

    string = &"Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1 ";
    ticket = try ticketScore(string.*, alloc);
    try std.testing.expectEqual(ticket.score, 2);
    try std.testing.expectEqual(ticket.matches, 2);
    try tickets.append(ticket);

    string = &"Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83";
    ticket = try ticketScore(string.*, alloc);
    try std.testing.expectEqual(ticket.score, 1);
    try std.testing.expectEqual(ticket.matches, 1);
    try tickets.append(ticket);

    string = &"Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36";
    ticket = try ticketScore(string.*, alloc);
    try std.testing.expectEqual(ticket.score, 0);
    try std.testing.expectEqual(ticket.matches, 0);
    try tickets.append(ticket);

    string = &"Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11";
    ticket = try ticketScore(string.*, alloc);
    try std.testing.expectEqual(ticket.score, 0);
    try std.testing.expectEqual(ticket.matches, 0);
    try tickets.append(ticket);

    string = &"Card   1:  8 86 59 90 68 52 55 24 37 69 | 10 55  8 86  6 62 69 68 59 37 91 90 24 22 78 61 58 89 52 96 95 94 13 36 81";
    ticket = try ticketScore(string.*, alloc);
    try std.testing.expectEqual(ticket.score, 512);
    try std.testing.expectEqual(ticket.matches, 10);

    try std.testing.expectEqual(getGameId("Card   1"), 1);

    try std.testing.expectEqual(cardCount(tickets), 30);
}
