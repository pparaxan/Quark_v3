const std = @import("std");
const libquark = @import("quark");

pub fn main() !void {
    const config = libquark.QuarkConfig.init()
        .title("Quark Application")
        .size(1280, 720) // this and width doesn't work, fix it later you idiot.
        .resize(libquark.SizeHint.min)
        .debug(true);

    const quark = try libquark.Quark.createWindow(config);
    try quark.execWindow();
}
