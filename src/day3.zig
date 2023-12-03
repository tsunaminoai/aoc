/// --- Day 3: Gear Ratios ---
/// You and the Elf eventually reach a gondola lift station; he says the
/// gondola lift will take you up to the water source, but this is as far as
/// he can bring you. You go inside.
///
/// It doesn't take long to find the gondolas, but there seems to be a problem:
/// they're not moving.
///
/// "Aaah!"
///
/// You turn around to see a slightly-greasy Elf with a wrench and a look of
/// surprise. "Sorry, I wasn't expecting anyone! The gondola lift isn't working
/// right now; it'll still be a while before I can fix it." You offer to help.
///
/// The engineer explains that an engine part seems to be missing from the
/// engine, but nobody can figure out which one. If you can add up all the part
/// numbers in the engine schematic, it should be easy to work out which part
/// is missing.
///
/// The engine schematic (your puzzle input) consists of a visual
/// representation of the engine. There are lots of numbers and symbols you
/// don't really understand, but apparently any number adjacent to a symbol,
/// even diagonally, is a "part number" and should be included in your sum.
/// (Periods (.) do not count as a symbol.)
///
/// Here is an example engine schematic:
///
/// 467..114..
/// ...*......
/// ..35..633.
/// ......#...
/// 617*......
/// .....+.58.
/// ..592.....
/// ......755.
/// ...$.*....
/// .664.598..
/// In this schematic, two numbers are not part numbers because they are not
/// adjacent to a symbol: 114 (top right) and 58 (middle right). Every other
/// number is adjacent to a symbol and so is a part number; their sum is 4361.
///
/// Of course, the actual engine schematic is much larger. What is the sum of
/// all of the part numbers in the engine schematic?
///
const std = @import("std");
const atoi = @import("root.zig").stringDigitsToNumber;

pub fn day3(writer: anytype, alloc: std.mem.Allocator) !void {
    var sum: u32 = 0;
    var file = try std.fs.cwd().openFile("inputs/day3.txt", .{});
    defer file.close();

    const text = try alloc.alloc(u8, try file.getEndPos());
    defer alloc.free(text);

    _ = try file.readAll(text);
    var out = try parseParts(text, alloc);
    defer out.deinit();

    for (out.parts.items) |p| {
        // std.debug.print("{any}\n", .{p});
        if (p.isValid)
            sum += p.number;
    }
    try writer.print("Sum of part numbers: {}\n", .{sum});
    try writer.print("Sum of gears: {}\n", .{getGearSum(out)});
}

const PartNumber = struct {
    startIndex: usize = 0,
    endIndex: usize = 0,
    lineNumber: usize = 0,
    number: u32 = 0,
    isValid: bool = false,
};

const Special = struct {
    index: usize,
    char: u8,
    adjacents: std.ArrayList(*PartNumber),
};

const ParseOutput = struct {
    parts: std.ArrayList(PartNumber),
    specials: std.ArrayList(Special),

    pub fn deinit(self: *ParseOutput) void {
        for (self.specials.items) |s|
            s.adjacents.deinit();
        self.specials.deinit();
        self.parts.deinit();
    }
    pub fn init(alloc: std.mem.Allocator) ParseOutput {
        return .{
            .parts = std.ArrayList(PartNumber).init(alloc),
            .specials = std.ArrayList(Special).init(alloc),
        };
    }
};

fn parseParts(input: []const u8, alloc: std.mem.Allocator) !ParseOutput {
    var ret = ParseOutput.init(alloc);
    var tempString = std.ArrayList(u8).init(alloc);
    defer tempString.deinit();

    var numState = false;
    var lineNumber: usize = 0;
    var tempNum = PartNumber{};
    var width: usize = 0;

    for (input, 0..) |c, i| {
        switch (c) {
            '0'...'9' => {
                if (!numState) {
                    tempNum = PartNumber{
                        .startIndex = i,
                        .lineNumber = lineNumber,
                    };
                }
                numState = true;
                try tempString.append(c);
            },
            else => |s| {
                if (numState) {
                    numState = false;
                    tempNum.endIndex = i - 1;
                    tempNum.number = try atoi(tempString.items);
                    try ret.parts.append(tempNum);
                    tempString.clearAndFree();
                }
                switch (s) {
                    '.' => {
                        numState = false;
                        continue;
                    },
                    '#', '*', '+', '$', '-', '/', '\\', '%', '@', '!', '(', ')', '&', '=' => {
                        numState = false;
                        try ret.specials.append(.{
                            .index = i,
                            .char = s,
                            .adjacents = std.ArrayList(*PartNumber).init(alloc),
                        });
                    },
                    '\n' => {
                        lineNumber += 1;
                        if (width == 0)
                            width = i + 1;
                    },
                    else => {
                        numState = false;
                        std.debug.panic("Unknown char: {c}\n", .{s});
                    },
                }
            },
        }
    }
    // std.debug.print("Width: {}\n", .{width});
    // for (specials.items) |s|
    //     std.debug.print("Special '{c}' found at {}\n", .{ s.char, s.index });
    for (ret.parts.items) |*pn| {
        if (try specialAdjacent(pn, ret.specials, width))
            pn.isValid = true;
    }

    return ret;
}

fn specialAdjacent(
    part: *PartNumber,
    specials: std.ArrayList(Special),
    width: usize,
) !bool {
    const len = part.endIndex - part.startIndex + 1;
    _ = len;
    const widthWithNewline = width;
    // take the \n into consideration with an aditional -/+ 1
    const upperLeft: usize = if (part.lineNumber != 0) part.startIndex - widthWithNewline - 1 else 0;
    const upperRight: usize = if (part.lineNumber != 0) part.endIndex - widthWithNewline + 1 else 0;
    const lowerLeft: usize = part.startIndex + widthWithNewline - 1;
    const lowerRight: usize = part.endIndex + widthWithNewline + 1;
    // std.debug.print(
    //     "Checking bounding box for {any} {},{},{},{}\n",
    //     .{ part, upperLeft, upperRight, lowerLeft, lowerRight },
    // );
    var ret = false;
    for (specials.items) |*s| {
        if (upperLeft <= s.index and upperRight >= s.index)
            ret = true;
        if (part.startIndex != 0 and part.startIndex - 1 <= s.index and part.endIndex + 1 >= s.index)
            ret = true;
        if (lowerLeft <= s.index and lowerRight >= s.index)
            ret = true;

        if (ret) {
            try s.adjacents.append(part);
            return ret;
        }
    }
    return ret;
}

fn getGearSum(partlist: ParseOutput) u32 {
    var sum: u32 = 0;
    for (partlist.specials.items) |s| {
        // std.debug.print("Checking for gears for {c}, adjacents: {}\n", .{ s.char, s.adjacents.items.len });
        if (s.char == '*' and s.adjacents.items.len == 2) {
            sum += s.adjacents.items[0].number * s.adjacents.items[1].number;
            // std.debug.print("Found gear: {}*{} = {}, ret = {}\n", .{
            //     s.adjacents.items[0].number,
            //     s.adjacents.items[1].number,
            //     s.adjacents.items[0].number * s.adjacents.items[1].number,
            //     sum,
            // });
        }
    }
    return sum;
}

test "day3" {
    const input =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    var pn = try parseParts(
        input,
        std.testing.allocator,
    );
    defer pn.deinit();

    var sum: u32 = 0;
    for (pn.parts.items) |p| {
        // std.debug.print("{any}\n", .{p});
        if (p.isValid)
            sum += p.number;
    }
    try std.testing.expectEqual(sum, 4361);
    try std.testing.expectEqual(getGearSum(pn), 467835);
}
