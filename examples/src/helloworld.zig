const std = @import("std");
const libquark = @import("quark");

pub fn main() !void {
    const config = libquark.QuarkConfig.init()
        .title("Quark Application")
        .size(1280, 720)
        .resize(libquark.SizeHint.MIN)
        .debug(true);
    // .setFrontend("frontend");

    const quark = try libquark.Quark.createWindow(config);
    try quark.execWindow();
    // try quark.destroy_window();
}
