const std = @import("std");

pub const SizeHint = enum(c_uint) {
    NONE = 0,
    MIN = 1,
    MAX = 2,
    FIXED = 3,
};

pub const QuarkConfig = struct {
    title: [:0]const u8 = "Quark Application",
    width: u16 = 800,
    height: u16 = 600,
    resizable: SizeHint = SizeHint.NONE,
    debug: bool = false,

    pub fn new() QuarkConfig {
        return QuarkConfig{};
    }

    pub fn setTitle(self: QuarkConfig, title: [:0]const u8) QuarkConfig {
        var config = self;
        config.title = title;
        return config;
    }

    pub fn setWidth(self: QuarkConfig, width: u16) QuarkConfig {
        var config = self;
        config.width = width;
        return config;
    }

    pub fn setHeight(self: QuarkConfig, height: u16) QuarkConfig {
        var config = self;
        config.height = height;
        return config;
    }

    pub fn setResizable(self: QuarkConfig, hint: SizeHint) QuarkConfig {
        var config = self;
        config.resizable = hint;
        return config;
    }

    pub fn setDebug(self: QuarkConfig, debug: bool) QuarkConfig {
        var config = self;
        config.debug = debug;
        return config;
    }
};
