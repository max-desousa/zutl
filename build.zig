const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod_zutl = b.addModule("zutl", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
        },
    });


    const exe = b.addExecutable(.{
        .name = "zutl_tests",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zutl", .module = mod_zutl },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    run_cmd.addPassthruArgs();

    const lib_zutl = b.addLibrary(.{
        .linkage = .static,
        .name = "zutl",
        .root_module = mod_zutl,
    });

    const installDir_docs = b.addInstallDirectory(.{
        .source_dir = lib_zutl.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });
    const step_docs = b.step("docs", "Generate HTML Documentation for the module");
    step_docs.dependOn(&installDir_docs.step);
    step_docs.dependOn(b.getInstallStep());
}
