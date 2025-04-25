const std = @import("std");
const libquark = @import("quark");

fn onResize(view: libquark.WebView, _: ?*anyopaque) void {
    const hint: u32 = 0;
    view.setSize(480, 320, hint) catch {};
}

pub fn main() !void {
    var window = libquark.WebView.create(false, null);
    try window.setTitle("libquarkv3");
    try window.dispatch(onResize, null);
    try window.setHtml("Thanks for using libquarkv3!");
    try window.run();
    try window.destroy();
}
