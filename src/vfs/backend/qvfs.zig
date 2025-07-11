const std = @import("std");
const mime_types = @import("mime_types.zig");
const frontend = @import("frontend");

const VFS_RUNTIME_MODULES = [_][]const u8{
    @embedFile("../frontend/core.js"),
    @embedFile("../frontend/interceptors.js"),
    @embedFile("../frontend/domHandler.js"),
    @embedFile("../frontend/cssProcessor.js"),
};

pub const QuarkVirtualFileSystem = struct {
    allocator: std.mem.Allocator,
    asset_registry: std.ArrayList(u8),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        return Self{
            .allocator = allocator,
            .asset_registry = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.asset_registry.deinit();
    }

    pub fn generate_injection_code(self: *Self) ![]u8 {
        // Inject core VFS runtime modules
        for (VFS_RUNTIME_MODULES) |module| {
            try self.asset_registry.appendSlice(module);
            try self.asset_registry.append('\n');
        }

        // Register all frontend assets
        for (frontend.resources) |resource| {
            try self.register_asset(resource.file, resource.path);
        }

        return try self.allocator.dupe(u8, self.asset_registry.items);
    }

    fn register_asset(self: *Self, file_name: []const u8, content: []const u8) !void {
        const base64_data = try self.encode_base64(content);
        defer self.allocator.free(base64_data);

        const mime_type = mime_types.detect_mime_type(file_name);

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

    fn encode_base64(self: *Self, data: []const u8) ![]u8 {
        const encoder = std.base64.standard.Encoder;
        const encoded_size = encoder.calcSize(data.len);
        const encoded = try self.allocator.alloc(u8, encoded_size);
        _ = encoder.encode(encoded, data);
        return encoded;
    }
};
