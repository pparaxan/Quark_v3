// const std = @import("std");
// const libquark = @import("quark");

// // fn onResize(view: libquark.WebView, _: ?*anyopaque) void {
// //     const hint: u32 = 0;
// //     view.setSize(480, 320, hint) catch {};
// // }

// pub fn main() !void {
//     var window = try libquark.create(true, null);
//     try window.setSize(480, 320, libquark.WebView.SizeHint.NONE);
//     try window.setTitle("libquarkv3");
//     // try window.dispatch(onResize, null);
//     try window.setHtml("Thanks for using libquarkv3!");
//     std.time.sleep(100 * std.time.ns_per_ms);
//     try window.run();
//     // try window.destroy();
// }

const std = @import("std");
const libquark = @import("quark");

pub fn main() !void {
    const config = libquark.QuarkConfig.new()
        .setTitle("Quark Application")
        .setWidth(1280)
        .setHeight(720)
        .setResizable(libquark.SizeHint.MIN)
        .setHtml("src_quark/index.html");

    const quark = try libquark.Quark.new(config);
    try quark.run();
}
