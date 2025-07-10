const std = @import("std");
const libquark = @import("quark");
// const libcrosssys = @import("crosssys"); // Linux only (for now); build.zig's broken.

pub fn main() !void {
    const config = libquark.WindowConfig.init()
        .with_title("Quark - reportsysinfo")
        .with_dimensions(1280, 720)
        .with_size_hint(libquark.WindowHint.min_size)
        .with_debug(true);

    var window = try libquark.create_window(config);
    try libquark.register_command(&window, "get_info", get_info);
    try libquark.execute_window(&window);
}

fn get_info(allocator: std.mem.Allocator, _: []const u8) []const u8 {
    // _ = allocator;
    const distro = "Arch Linux";
    const kernel = "6.15.5-1-catgirl-edition"; // https://github.com/a-catgirl-dev/linux-catgirl-edition
    // const distro = libcrosssys.distro.main();
    // const kernel = libcrosssys.kernel.main();

    // Use a static buffer or ensure the returned string is properly managed
    const result = std.fmt.allocPrint(allocator,
        \\{{
        \\  "distro": "{s}",
        \\  "kernel": "{s}"
        \\}}
    , .{ distro, kernel }) catch |err| @errorName(err);

    return result;
}
