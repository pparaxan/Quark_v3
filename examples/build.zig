pub fn build(b: *@import("std").Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .Debug,
    });

    const lib_quark = b.dependency("quark", .{});

    const executable = b.addExecutable(.{
        .name = "quark_examples",
        .root_source_file = b.path("src/helloworld.zig"),
        .target = target,
        .optimize = optimize,
    });

    executable.root_module.addImport("quark", lib_quark.module("webview"));
    executable.linkLibrary(lib_quark.artifact("quark"));
    // executable.linkLibC();

    switch (@import("builtin").os.tag) { // more bloat, dw
        .windows => {
            executable.linkSystemLibrary("ole32");
            executable.linkSystemLibrary("shlwapi");
            executable.linkSystemLibrary("version");
            executable.linkSystemLibrary("advapi32");
            executable.linkSystemLibrary("shell32");
            executable.linkSystemLibrary("user32");
        },
        .macos => executable.linkFramework("WebKit"),
        .linux => {
            executable.linkSystemLibrary("gtk+-3.0");
            executable.linkSystemLibrary("webkit2gtk-4.0");
        },
        else => {},
    }

    b.installArtifact(executable);

    const run_cmd = b.addRunArtifact(executable);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
