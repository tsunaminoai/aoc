const std = @import("std");

const days = &[_][]const u8{
    // zig fmt: off
    // "1",
    "2","3","4","5","6","7",
    "8","9", "10", "11"
    // zig fmt: on
};



pub fn build(b: *std.Build) void {
 
    const target = b.standardTargetOptions(.{});

  
    const optimize = b.standardOptimizeOption(.{});

    const test_step = b.step("test", "Run tests");
    const documentation = b.option(bool, "docs", "Generate documentation") orelse false;
    const docs_step = b.step("docs", "Copy documentation artifacts to prefix path");

    inline for(days)|day|{
        const exe = b.addExecutable(.{
            .name = "day" ++ day,
            .root_source_file = .{ .path = "src/main.zig" },
            .target = target,
            .optimize = optimize,
        });
        const libModule = b.addModule("aoc", .{
            .source_file = .{ .path = "src/day" ++  day ++ ".zig"  },
        });
        const lib = b.addStaticLibrary(.{
            .name = "aoc",
            .root_source_file = .{  .path = "src/day" ++  day ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("aoc", libModule);
        exe.linkLibrary(lib);
        const dayopt = b.addOptions();
        dayopt.addOption([]const u8, "DAY", day);
        exe.addOptions("config", dayopt);

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        const run_step = b.step("day" ++ day, "Run day "++day++"'s file");
        run_step.dependOn(&run_cmd.step);

        const test_module = b.fmt("src/day{s}.zig", .{day});
        var exe_tests = b.addTest(.{
            .root_source_file = .{ .path = test_module },
        });
        test_step.dependOn(&exe_tests.step);


        if (documentation) {
            const install_docs =  b.addInstallDirectory(.{
                .source_dir =  lib.getEmittedDocs(),
                .install_dir = .prefix,
                .install_subdir = "docs",
            });

            docs_step.dependOn(&install_docs.step);
        }
    }
    
    // // This *creates* a Run step in the build graph, to be executed when another
    // // step is evaluated that depends on it. The next line below will establish
    // // such a dependency.
    // const run_cmd = b.addRunArtifact(exe);

    // // By making the run step depend on the install step, it will be run from the
    // // installation directory rather than directly from within the cache directory.
    // // This is not necessary, however, if the application depends on other installed
    // // files, this ensures they will be present and in the expected location.
    // run_cmd.step.dependOn(b.getInstallStep());

    // // This allows the user to pass arguments to the application in the build
    // // command itself, like this: `zig build run -- arg1 arg2 etc`
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // // This creates a build step. It will be visible in the `zig build --help` menu,
    // // and can be selected like this: `zig build run`
    // // This will evaluate the `run` step rather than the default, which is "install".
    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    // // Creates a step for unit testing. This only builds the test executable
    // // but does not run it.
    // const lib_unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/root.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);
}
