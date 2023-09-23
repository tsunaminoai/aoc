const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    var allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("src/day1/input", .{});
    defer file.close();

    const read_buffer = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(read_buffer);

    var it = std.mem.split(u8, read_buffer, "\n");

    var elves = std.ArrayList(u32).init(allocator);
    defer elves.deinit();

    var avg: u32 = 0;
    while (it.next()) |line| {
        var int = std.fmt.parseInt(u32, line, 10) catch |err| {
            if (err == error.InvalidCharacter) {
                try elves.append(avg);
                avg = 0;
                continue;
            }
            return err;
        };
        avg += int;
    }
    var elfList = try elves.toOwnedSlice();
    std.mem.sort(u32, elfList, {}, comptime std.sort.asc(u32));
    for (elfList, 0..) |item, v| {
        std.debug.print("Elf {}: {}\n", .{ v, item });
    }
}
