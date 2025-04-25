const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe
    });

    const webview = b.dependency("webview", .{});

    const webview_trans = b.addTranslateC(.{
        .root_source_file = webview.path("core/include/webview/webview.h"),
        .optimize = optimize,
        .target = target,
    }).createModule();

    const libquark_mod = b.addModule("webview", .{
    // _ = b.addModule("webview", .{
        .root_source_file = b.path("src/binding.zig")
    // }).addImport("webview_trans", webview_trans);
    });
    libquark_mod.addImport("webview_trans", webview_trans);

    const libquark = b.addStaticLibrary(.{
        .name = "quark",
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });
    libquark.addIncludePath(webview.path("core/include/webview/"));
    libquark.root_module.addCMacro("WEBVIEW_STATIC", "1");
    libquark.linkLibCpp();
    switch (@import("builtin").os.tag) {
        // .windows => {
        //     libquark.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++14"} });
        //     libquark.addIncludePath(b.path("external/WebView2/"));
        //     libquark.linkSystemLibrary("ole32");
        //     libquark.linkSystemLibrary("shlwapi");
        //     libquark.linkSystemLibrary("version");
        //     libquark.linkSystemLibrary("advapi32");
        //     libquark.linkSystemLibrary("shell32");
        //     libquark.linkSystemLibrary("user32");
        // },
        .macos => {
            libquark.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            libquark.linkFramework("WebKit");
        },
        .freebsd => {
            libquark.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/cairo/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/gtk-3.0/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/glib-2.0/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/lib/glib-2.0/include/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.0/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            libquark.linkSystemLibrary("gtk-3");
            libquark.linkSystemLibrary("webkit2gtk-4.0");
        },
        .linux => {
            libquark.addCSourceFile(.{ .file = webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            libquark.linkSystemLibrary("gtk+-3.0");
            libquark.linkSystemLibrary("webkit2gtk-4.0");
        },
        else => {
            @compileError("Unsupported operating system for libquark.");
        }
    }
    b.installArtifact(libquark);
}
