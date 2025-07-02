const std = @import("std");

pub const SizeHint = enum(c_uint) {
    none = 0,
    min = 1,
    // max = 2, // webkitgtk doesn't support this.
    fixed = 3,
};

pub const QuarkConfig = struct {
    _title: [:0]const u8 = "Quark Application",
    _width: u16 = 800,
    _height: u16 = 600,
    _resize: SizeHint = .min,
    _debug: bool = false,

    pub fn init() QuarkConfig {
        return QuarkConfig{};
    }

    pub fn title(self: QuarkConfig, t: [:0]const u8) QuarkConfig {
        var config = self;
        config._title = t; // itle
        return config;
    }

    pub fn size(self: QuarkConfig, w: u16, h: u16) QuarkConfig {
        var config = self;
        config._width = w; // idth
        config._height = h; // eight
        return config;
    }

    pub fn resize(self: QuarkConfig, h: SizeHint) QuarkConfig {
        var config = self;
        config._resize = h; // int
        return config;
    }

    pub fn debug(self: QuarkConfig, d: bool) QuarkConfig {
        var config = self;
        config._debug = d; // ebug
        return config;
    }
};
