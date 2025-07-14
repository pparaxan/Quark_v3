const std = @import("std");
const libquark = @import("quark");

pub fn main() !void {
    const config = libquark.WindowConfig.init()
        .withTitle("Quark - minimal")
        .withDimensions(1280, 720)
        .withSizeHint(libquark.WindowHint.resizable)
        .withDebug(true);

    var window = try libquark.createWindow(config);
    try libquark.executeWindow(&window);
    try libquark.destroyWindow(&window);
}
