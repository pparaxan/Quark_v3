const std = @import("std");
const libquark = @import("quark");

pub fn main() !void {
    const config = libquark.QuarkConfig.new()
        .setTitle("Quark Application")
        .setWidth(1280)
        .setHeight(720) // this and width doesn't work, fix it later you idiot.
        .setResizable(libquark.SizeHint.MIN)
        .setDebug(true);
        // .setFrontend("frontend");

    const quark = try libquark.Quark.createWindow(config);
    try quark.execWindow();
    // try quark.destroy_window();
}
