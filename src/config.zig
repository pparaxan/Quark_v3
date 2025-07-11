const std = @import("std");

pub const WindowHint = enum(c_uint) {
    resizable = 0,
    min_size = 1,
    // max_size = 2, // webkitgtk-6.0 doesn't support this.
    fixed_size = 3,
};

pub const WindowConfig = struct {
    title: [:0]const u8 = "Quark Application",
    width: u16 = 800,
    height: u16 = 600,
    size_hint: WindowHint = .resizable,
    debug_mode: bool = false,

    const Self = @This();

    pub fn init() Self {
        return Self{};
    }

    pub fn withTitle(self: Self, new_title: [:0]const u8) Self {
        var config = self;
        config.title = new_title;
        return config;
    }

    pub fn withDimensions(self: Self, w: u16, h: u16) Self {
        var config = self;
        config.width = w;
        config.height = h;
        return config;
    }

    pub fn withSizeHint(self: Self, hint: WindowHint) Self {
        var config = self;
        config.size_hint = hint;
        return config;
    }

    pub fn withDebug(self: Self, enable: bool) Self {
        var config = self;
        config.debug_mode = enable;
        return config;
    }
};
