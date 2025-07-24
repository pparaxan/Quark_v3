const std = @import("std");

/// Specifies the window behavior of a Quark application.
///
/// These hints control how the user can interact with the window size,
/// mapping to the underlying webview implementation constraints.
pub const WindowHint = enum(c_uint) {
    resizable = 0,
    min_size = 1,
    fixed_size = 3,
};

/// Configuration structure for creating a Quark application.
///
/// Provides a builder-pattern interface for setting window properties
/// including dimensions, title, and resize behavior.
///
/// Example:
///   const config = WindowConfig.init().withTitle("My App").withDimensions(1024, 768).withSizeHint(WindowHint.fixed_size);
pub const WindowConfig = struct {
    title: [:0]const u8 = "Quark Application",
    width: u16 = 800,
    height: u16 = 600,
    size_hint: WindowHint = .resizable,
    debug_mode: bool = false, // deprecate this? make it true when in debug mode but once you're building in release mode it goes to false auto..

    const Self = @This();

    /// Creates a new WindowConfig with default values.
    ///
    /// Returns a WindowConfig instance with the default values.
    pub fn init() Self {
        return Self{};
    }

    /// Sets the window title.
    ///
    /// This value determines the value given to the underlying operating system
    /// what title to give your application.
    pub fn withTitle(self: Self, new_title: [:0]const u8) Self {
        var config = self;
        config.title = new_title;
        return config;
    }

    /// Sets the window dimensions.
    ///
    /// The width and height value determines the width and height of the webview should render at.
    pub fn withDimensions(self: Self, w: u16, h: u16) Self {
        var config = self;
        config.width = w;
        config.height = h;
        return config;
    }

    /// Sets the window size behavior hint.
    ///
    /// This value determines the resizing conditions for the Quark application.
    pub fn withSizeHint(self: Self, hint: WindowHint) Self {
        var config = self;
        config.size_hint = hint;
        return config;
    }

    /// Enables or disables debug mode.
    ///
    /// This value shows developer tools and additional debugging information via `right-click > Inspect Element`.
    pub fn withDebug(self: Self, enable: bool) Self {
        var config = self;
        config.debug_mode = enable;
        return config;
    }
};
