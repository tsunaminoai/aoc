const std = @import("std");

const skip = &[_]u8{ 11, 12, 13, 14 };

pub fn build(b: *std.Build) !void {
    const timing_cmd = b.option(bool, "timing", "Add timing logic to runs") orelse false;

    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe_targets = b.step("exe_targets", "Build executables for each day");
    const docs = b.step("docs", "Build documentation");
    const timing_opt = b.addOptions();
    timing_opt.addOption(bool, "timing", timing_cmd);

    var day: u8 = 1;
    while (day <= 15) : (day += 1) {
        if (std.mem.indexOf(u8, skip, &[_]u8{day}) != null)
            continue;
        var buf: [10]u8 = undefined;

        const day_str = try std.fmt.bufPrint(&buf, "day{d}", .{day});

        const src_file = try std.mem.concat(b.allocator, u8, &.{
            day_str,
            ".zig",
        });
        const src_path = .{
            .path = try std.mem.concat(b.allocator, u8, &.{
                "src/",
                src_file,
            }),
        };
        const dayopt = b.addOptions();
        dayopt.addOption([]const u8, "DAY", day_str);

        const exe = b.addExecutable(.{
            .name = day_str,
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
            .single_threaded = true,
        });
        const day_module = b.addModule("day", .{
            .source_file = src_path,
        });
        const day_lib = b.addStaticLibrary(.{
            .name = day_str,
            .root_source_file = src_path,
            .target = target,
            .optimize = optimize,
            .single_threaded = true,
        });
        exe.linkLibrary(day_lib);
        exe.addModule("day", day_module);
        exe.addOptions("config", dayopt);
        exe.addOptions("timing", timing_opt);
        b.installArtifact(exe);

        exe_targets.dependOn(&exe.step);

        const run_cmd = b.addRunArtifact(exe);

        const test_step = b.addTest(.{
            .name = day_str,
            .root_source_file = src_path,
            .target = target,
            .optimize = optimize,
        });
        exe_targets.dependOn(&test_step.step);

        const run_name = try std.mem.concat(b.allocator, u8, &.{
            "run_",
            day_str,
        });
        const run_desc = try std.mem.concat(b.allocator, u8, &.{
            "Run ",
            day_str,
        });
        const run_step = b.step(run_name, run_desc);
        run_step.dependOn(&run_cmd.step);

        const docs_dir = try std.mem.concat(b.allocator, u8, &.{
            "docs/",
            day_str,
        });
        const docs_install = b.addInstallDirectory(.{
            .install_dir = .prefix,
            .install_subdir = docs_dir,
            .source_dir = day_lib.getEmittedDocs(),
        });

        docs.dependOn(&docs_install.step);
    }

    const test_all = b.step("test_all", "Run all tests");
    test_all.dependOn(exe_targets);

    const run_all = b.step("run_all", "Run all days");
    run_all.dependOn(exe_targets);

    const clean = b.step("clean", "Remove the zig local directories");
    clean.dependOn(&b.addRemoveDirTree("zig-out").step);
    clean.dependOn(&b.addRemoveDirTree("zig-cache").step);
}
