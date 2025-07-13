const std = @import("std");
const utils = @import("utils.zig");

pub fn platform(b: *std.Build, libquark: *std.Build.Step.Compile, lib_webview: *std.Build.Dependency, lib_webview2: *std.Build.Dependency) !void {
    libquark.addIncludePath(lib_webview.path("core/include/"));
    libquark.addIncludePath(lib_webview.path("core/include/webview/"));
    libquark.root_module.addCMacro("WEBVIEW_STATIC", "1");
    libquark.linkLibCpp();

    switch (@import("builtin").os.tag) {
        .windows => {
            const sdk = try utils.getWindowsSDKPath(b.allocator);
            const winrt = try std.fmt.allocPrint(b.allocator, "{s}\\winrt", .{sdk});

            libquark.addIncludePath(lib_webview2.path("build/native/include/"));
            libquark.addCSourceFile(.{ .file = lib_webview.path("core/src/webview.cc"), .flags = &.{"-std=c++14"} });
            libquark.addIncludePath(.{ .cwd_relative = winrt });

            libquark.linkSystemLibrary("version");
            libquark.linkSystemLibrary("ole32");
            libquark.linkSystemLibrary("shlwapi");
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
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/webkitgtk-4.1/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/pango-1.0/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/harfbuzz/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/gdk-pixbuf-2.0/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/atk-1.0/" });
            libquark.addIncludePath(.{ .cwd_relative = "/usr/local/include/libsoup-3.0/" });
            libquark.linkSystemLibrary("gtk4");
            libquark.linkSystemLibrary("webkitgtk-6.0");
        },
        .linux => {
            libquark.addCSourceFile(.{ .file = lib_webview.path("core/src/webview.cc"), .flags = &.{"-std=c++11"} });
            libquark.linkSystemLibrary("gtk4");
            libquark.linkSystemLibrary("webkitgtk-6.0");
        },
        else => {
            @compileError("Unsupported operating system for libquark.");
        },
    }
}
