const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });

    const lib_webview = b.dependency("webview", .{});
    const lib_webview2 = b.dependency("webview2", .{});

    const webview = b.addTranslateC(.{
        .root_source_file = lib_webview.path("core/include/webview/webview.h"),
        .optimize = optimize,
        .target = target,
    }).createModule();

    const webview2 = b.addTranslateC(.{
        .root_source_file = lib_webview.path("build/native/include/WebView2.h"),
        .optimize = optimize,
        .target = target,
    }).createModule();

    const libquark_mod = b.addModule("libquark", .{
        .root_source_file = b.path("src/root.zig"),
    });
    libquark_mod.addImport("webview", webview);
    libquark_mod.addImport("webview2", webview2);

    const libquark = b.addStaticLibrary(.{
        .name = "quark",
        .root_source_file = b.path("src/root.zig"),
        .optimize = optimize,
        .target = target,
    });
    libquark.addIncludePath(lib_webview.path("core/include/webview/"));
    libquark.root_module.addCMacro("WEBVIEW_STATIC", "1");
    libquark.linkLibCpp();
    switch (@import("builtin").os.tag) {
        .windows => {
            libquark.addCSourceFile(.{ .file = lib_webview.path("core/src/webview.cc"), .flags = &.{"-std=c++14"} });
            libquark.addIncludePath(lib_webview2.path("build/native/include/"));
            libquark.addCSourceFile(.{ .file = lib_webview2.path("build/native/include/WebView2.h") });

            libquark.addIncludePath(lib_webview2.path("C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/winrt")); // don't make this be a fixed version
            libquark.addCSourceFile(.{ .file = lib_webview2.path("C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/winrt/EventToken.h") });

            // libquark.addIncludePath(.{ .cwd_relative = "C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/shared" });
            // libquark.addIncludePath(.{ .cwd_relative = "C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/winrt" });
            // libquark.addIncludePath(.{ .cwd_relative = "C:/Program Files (x86)/Windows Kits/10/Include/10.0.26100.0/ucrt" });

            libquark.linkSystemLibrary("ole32");
            libquark.linkSystemLibrary("shlwapi");
            libquark.linkSystemLibrary("version");
            libquark.linkSystemLibrary("advapi32");
            libquark.linkSystemLibrary("shell32");
            libquark.linkSystemLibrary("user32");
        },
        .macos => {
            libquark.addCSourceFile(.{ .file = lib_webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            libquark.linkFramework("WebKit");
        },
        .freebsd => {
            libquark.addCSourceFile(.{ .file = lib_webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
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
            libquark.addCSourceFile(.{ .file = lib_webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            libquark.linkSystemLibrary("gtk+-3.0");
            libquark.linkSystemLibrary("webkit2gtk-4.0");
        },
        else => {
            @compileError("Unsupported operating system for libquark.");
        },
    }
    b.installArtifact(libquark);
}
