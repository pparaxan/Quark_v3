const std = @import("std");
const binder = @import("binder");
const utils = @import("utils.zig");

pub fn modules(b: *std.Build, lib_webview: *std.Build.Dependency, lib_webview2: *std.Build.Dependency, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !void {
    const frontend = try binder.generate(b, .{
        .source_dir = "src_quark",
        .target_file = "binder.zig",
        .namespace = "quark_frontend",
    });

    const webview_mod = b.addTranslateC(.{
        .root_source_file = lib_webview.path("core/include/webview/webview.h"),
        .optimize = optimize,
        .target = target,
    }).createModule();

    const frontend_mod = b.createModule(.{
        .root_source_file = .{ .cwd_relative = frontend },
    });

    const libquark_mod = b.addModule("libquark", .{
        .root_source_file = b.path("src/root.zig"),
    });

    if (target.result.os.tag == .windows) {
        const sdk = try utils.getWindowsSDKPath(b.allocator);

        const webview2_translate = b.addTranslateC(.{
            .root_source_file = lib_webview2.path("build/native/include/WebView2.h"),
            .optimize = optimize,
            .target = target,
        });

        const winrt = try std.fs.path.join(b.allocator, &.{ sdk, "winrt" });
        const um = try std.fs.path.join(b.allocator, &.{ sdk, "um" });
        const shared = try std.fs.path.join(b.allocator, &.{ sdk, "shared" });
        const ucrt = try std.fs.path.join(b.allocator, &.{ sdk, "ucrt" });

        webview2_translate.addSystemIncludePath(.{ .cwd_relative = winrt });
        webview2_translate.addSystemIncludePath(.{ .cwd_relative = um });
        webview2_translate.addSystemIncludePath(.{ .cwd_relative = shared });
        webview2_translate.addSystemIncludePath(.{ .cwd_relative = ucrt });

        const webview2_mod = webview2_translate.createModule();
        libquark_mod.addImport("webview2", webview2_mod);
    }

    libquark_mod.addImport("webview", webview_mod);
    libquark_mod.addImport("frontend", frontend_mod);
}
