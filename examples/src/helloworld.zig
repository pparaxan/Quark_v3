const std = @import("std");
const libquark = @import("quark");

pub fn main() !void {
    const config = libquark.QuarkConfig.new()
        .setTitle("Quark Application")
        .setWidth(1280)
        .setHeight(720)
        .setResizable(libquark.SizeHint.MIN)
        .setDebug(true);

    const quark = try libquark.Quark.new(config);
    try quark.run();
}
