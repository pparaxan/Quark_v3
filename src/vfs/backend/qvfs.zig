//! This module provides a virtual file system for embedding frontend assets
//! directly into the Zig application, handling Base64 encoding and JavaScript
//! injection code generation for the frontend.

const std = @import("std");
const mime_types = @import("mime_types.zig");
const frontend = @import("frontend");

const frontend_modules = [_][]const u8{
    @embedFile("../frontend/core.js"),
    @embedFile("../frontend/interceptors.js"),
    @embedFile("../frontend/domHandler.js"),
    @embedFile("../frontend/cssProcessor.js"),
};

/// This struct helps embed assets that's found via the
/// [binder](https://codeberg.org/pparaxan/binder) file.
pub const QuarkVirtualFileSystem = struct {
    allocator: std.mem.Allocator,
    asset_registry: std.ArrayList(u8),

    const Self = @This();

    /// Initializes the QVFS instance
    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .asset_registry = std.ArrayList(u8).init(allocator),
        };
    }

    /// Generate JavaScript injection code that registers all frontend assets
    /// in the webview's global `window.__QUARK_VFS__` object.
    /// https://codeberg.org/pparaxan/Quark/src/branch/master/src/vfs/frontend
    ///
    /// This method processes all frontend assets, encoding them as Base64
    /// and creates a JavaScript object structure that can be injected
    /// into the WebView as URL blobs.
    pub fn generateInjectionCode(self: *Self) ![]u8 {
        for (frontend_modules) |module| {
            try self.asset_registry.appendSlice(module);
            try self.asset_registry.append('\n');
        }

        for (frontend.resources) |resource| {
            try self.registerAssets(resource.file, resource.path);
        }

        return try self.allocator.dupe(u8, self.asset_registry.items);
    }

    /// Register a _single_ asset by encoding its content as Base64 and generating
    /// the corresponding JavaScript object entry.
    fn registerAssets(self: *Self, file_name: []const u8, content: []const u8) !void {
        const base64_data = try self.encodeBase64(content);
        defer self.allocator.free(base64_data);

        const mime_type = mime_types.detectMimeType(file_name);

        try self.asset_registry.writer().print(
            \\
            \\window.__QUARK_VFS__["{s}"] = {{
            \\  content: "{s}",
            \\  mimeType: "{s}",
            \\  size: {d}
            \\}};
            \\
        , .{ file_name, base64_data, mime_type, content.len });
    }

    /// Encode binary data as Base64 using the standard Base64 alphabet.
    fn encodeBase64(self: *Self, data: []const u8) ![]u8 {
        const encoder = std.base64.standard.Encoder;
        const encoded_size = encoder.calcSize(data.len);
        const encoded = try self.allocator.alloc(u8, encoded_size);
        _ = encoder.encode(encoded, data);
        return encoded;
    }
};
