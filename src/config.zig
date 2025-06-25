const std = @import("std");

pub const SizeHint = enum(c_uint) { // revert this back to it being capitalized
    NONE = 0,
    MIN = 1,
    MAX = 2,
    FIXED = 3,
};

pub const QuarkConfig = struct {
    _title: [:0]const u8 = "Quark Application",
    _width: u16 = 800,
    _height: u16 = 600,
    _resize: SizeHint = SizeHint.MIN,
    _debug: bool = false,
    _frontend: [:0]const u8 = "frontend",

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

    pub fn frontend(self: QuarkConfig, dir: [:0]const u8) QuarkConfig {
        var config = self;
        config._frontend = dir; // ectory
        return config;
    }

    pub fn locateFrontend(self: QuarkConfig, allocator: std.mem.Allocator) ![]u8 { // This is used in build.zig
        return try std.fmt.allocPrint(allocator, "{s}", .{self._frontend});
    }
};
