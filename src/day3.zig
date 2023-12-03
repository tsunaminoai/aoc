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
    _ = alloc;
    _ = writer;
}

const PartNumber = struct {
    startIndex: usize = 0,
    endIndex: usize = 0,
    lineNumber: usize = 0,
    number: u32 = 0,
    isValid: bool = false,
};

fn parseParts(input: []const u8, alloc: std.mem.Allocator) !std.ArrayList(PartNumber) {
    var partNumbers = std.ArrayList(PartNumber).init(alloc);
    var specialIndicies = std.ArrayList(usize).init(alloc);
    defer specialIndicies.deinit();
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
                    try partNumbers.append(tempNum);
                    tempString.clearAndFree();
                }
                switch (s) {
                    '.' => {
                        numState = false;
                        continue;
                    },
                    '#', '*', '+', '$' => {
                        numState = false;
                        try specialIndicies.append(i - 1);
                    },
                    '\n' => {
                        lineNumber += 1;
                        if (width == 0)
                            width = i;
                    },
                    else => {
                        numState = false;
                        std.debug.print("Unknown char: {c}\n", .{s});
                    },
                }
            },
        }
    }
    // std.debug.print("{any}\n", .{specialIndicies});
    for (partNumbers.items) |*pn| {
        if (specialAdjacent(pn, specialIndicies, width))
            pn.isValid = true;
    }
    return partNumbers;
}

fn specialAdjacent(
    part: *PartNumber,
    specials: std.ArrayList(usize),
    width: usize,
) bool {
    const len = part.endIndex - part.startIndex + 1;
    _ = len;
    const upperLeft = if (part.lineNumber != 0) part.startIndex - width - 1 else 0;
    const upperRight = if (part.lineNumber != 0) part.endIndex - width + 1 else 0;
    const lowerLeft = part.startIndex + width - 1;
    const lowerRight = part.endIndex + width + 1;
    for (specials.items) |s| {
        if (upperLeft <= s and upperRight >= s)
            return true;
        if (part.startIndex % width != 0 and part.startIndex - 1 <= s and part.endIndex + 1 >= s)
            return true;
        if (lowerLeft <= s and lowerRight >= s)
            return true;
    }
    return false;
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
    const pn = try parseParts(
        input,
        std.testing.allocator,
    );
    defer pn.deinit();
    std.debug.print("{any}\n", .{pn});
}
