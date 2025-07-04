const std = @import("std");
const libquark = @import("quark");

pub fn main() !void {
    const config = libquark.WindowConfig.init()
        .with_title("Quark - minimal")
        .with_dimensions(1280, 720)
        .with_size_hint(libquark.WindowHint.min_size)
        .with_debug(true);

    const window = try libquark.create_window(config);
    try libquark.execute_window(window);
}
