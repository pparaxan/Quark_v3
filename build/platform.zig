const std = @import("std");

pub fn platform(libquark: *std.Build.Step.Compile, lib_webview: *std.Build.Dependency, lib_webview2: *std.Build.Dependency) !void {
    libquark.addIncludePath(lib_webview.path("core/include/"));
    libquark.addIncludePath(lib_webview.path("core/include/webview/"));
    libquark.root_module.addCMacro("WEBVIEW_STATIC", "1");
    libquark.linkLibCpp();

    switch (@import("builtin").os.tag) {
        .windows => {
            libquark.addIncludePath(lib_webview2.path("build/native/include/"));
            libquark.addCSourceFile(.{ .file = lib_webview.path("core/src/webview.cc"), .flags = &.{"-std=c++14"} });
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
        .freebsd => { // not tested, clean up.
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
