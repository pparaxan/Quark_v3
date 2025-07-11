const std = @import("std");
const libquark = @import("quark");
const libcrosssys = @import("crosssys");
const builtin = @import("builtin").os.tag;

pub fn main() !void {
    const config = libquark.WindowConfig.init()
        .with_title("Quark - reportsysinfo")
        .with_dimensions(1280, 720)
        .with_size_hint(libquark.WindowHint.min_size)
        .with_debug(true);

    var window = try libquark.create_window(config);
    try libquark.register_command("get_info", get_info);
    try libquark.execute_window(&window);
}

fn getDistroInfo() ![]const u8 {
    return switch (builtin) {
        .linux => libcrosssys.distro.Linux.getDistro(),
        // .windows => libcrosssys.cs.distro.Windows.getDistro(),
        // .macos => libcrosssys.cs.distro.MacOS.getDistro(),
        // .freebsd, .openbsd, .netbsd, .dragonfly => libcrosssys.cs.distro.BSD.getDistro(),
        else => error.UnsupportedOSForCrossSys,
    };
}

fn getKernelInfo() ![]const u8 {
    return switch (builtin) {
        .linux => libcrosssys.kernel.Linux.getKernel(),
        // .windows => libcrosssys.kernel.Windows.getKernel(),
        // .macos => libcrosssys.kernel.MacOS.getKernel(),
        // .freebsd, .openbsd, .netbsd, .dragonfly => libcrosssys.kernel.BSD.getKernel(),
        else => error.UnsupportedOSForCrossSys,
    };
}

fn get_info(allocator: std.mem.Allocator, _: []const u8) []const u8 {
    const distro = getDistroInfo() catch "Unknown";
    const kernel = getKernelInfo() catch "Unknown";

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
