pub fn build(b: *@import("std").Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .Debug,
    });

    const lib_quark = b.dependency("quark", .{});

    const executable = b.addExecutable(.{
        .name = "quark_examples",
        .root_source_file = b.path("src/helloworld.zig"), // add more examples over time
        .target = target,
        .optimize = optimize,
    });

    executable.root_module.addImport("quark", lib_quark.module("libquark"));
    executable.linkLibrary(lib_quark.artifact("quark"));

    b.installArtifact(executable);

    const run_cmd = b.addRunArtifact(executable);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
