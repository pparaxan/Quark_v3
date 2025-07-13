const std = @import("std");
const d = @import("build/dependencies.zig");
const m = @import("build/modules.zig");
const p = @import("build/platform.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    const deps = try d.dependencies(b);
    const lib_webview = deps[0];
    const lib_webview2 = deps[1];

    try m.modules(b, lib_webview, lib_webview2, target, optimize);

    const libquark = b.addLibrary(.{
        .name = "quark",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .static,
    });

    try p.platform(b, libquark, lib_webview, lib_webview2);

    b.installArtifact(libquark);
}
