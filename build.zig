const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const version = b.option(
        []const u8,
        "version",
        "Override the version string",
    ) orelse "0.1.3"; // Fallback version number

    const build_options = b.addOptions();
    build_options.addOption([]const u8, "version", version);

    const album_utils_mod = b.createModule(.{
        .root_source_file = b.path("src/album_utils.zig"),
        .link_libc = true,
    });

    const config_utils_mod = b.createModule(.{
        .root_source_file = b.path("src/config_utils.zig"),
        .link_libc = true,
    });
    const exe = b.addExecutable(.{
        .name = "albumfetch",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("album_utils", album_utils_mod);
    exe.root_module.addImport("config_utils", config_utils_mod);
    exe.root_module.addImport("build_options", build_options.createModule());

    if (optimize != .Debug) {
        exe.root_module.strip = true;
    }
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    // exe_tests.root_module.addImport("album_utils", album_utils_mod);
    // exe_tests.root_module.addImport("config_utils", config_utils_mod);
    // exe_tests.root_module.addImport("color_utils", color_utils_mod);
    // exe_tests.root_module.addImport("album", album_mod);
    // exe_tests.root_module.addImport("time_utils", time_mod);
    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    // test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
