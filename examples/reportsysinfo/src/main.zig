const std = @import("std");
const libquark = @import("quark");
const libcrosssys = @import("crosssys");
const builtin = @import("builtin").os.tag;

pub fn main() !void {
    const config = libquark.WindowConfig.init()
        .withTitle("Quark - reportsysinfo")
        .withDimensions(1280, 720)
        .withSizeHint(libquark.WindowHint.min_size)
        .withDebug(true);

    var window = try libquark.createWindow(config);
    try libquark.registerCommand("reportSystemInfo", reportSystemInfo);
    try libquark.executeWindow(&window);
}

fn fetchDistroInfo() ![]const u8 {
    return switch (builtin) {
        .linux => libcrosssys.distro.Linux.getDistro(),
        // .windows => libcrosssys.cs.distro.Windows.getDistro(),
        // .macos => libcrosssys.cs.distro.MacOS.getDistro(),
        // .freebsd, .openbsd, .netbsd, .dragonfly => libcrosssys.cs.distro.BSD.getDistro(),
        else => error.UnsupportedOSForCrossSys,
    };
}

fn fetchKernelInfo() ![]const u8 {
    return switch (builtin) {
        .linux => libcrosssys.kernel.Linux.getKernel(),
        // .windows => libcrosssys.kernel.Windows.getKernel(),
        // .macos => libcrosssys.kernel.MacOS.getKernel(),
        // .freebsd, .openbsd, .netbsd, .dragonfly => libcrosssys.kernel.BSD.getKernel(),
        else => error.UnsupportedOSForCrossSys,
    };
}

fn reportSystemInfo(allocator: std.mem.Allocator, _: []const u8) []const u8 {
    const distro = fetchDistroInfo() catch "Unknown";
    const kernel = fetchKernelInfo() catch "Unknown";

    const distro_str = std.mem.sliceTo(distro, 0);
    const kernel_str = std.mem.sliceTo(kernel, 0);

    const result = std.fmt.allocPrint(allocator,
        \\{{
        \\  "distro": "{s}",
        \\  "kernel": "{s}"
        \\}}
    , .{ distro_str, kernel_str }) catch |err| @errorName(err);

    return result;
}
