//! This module just provides utilities for safely handling JavaScript code
//! generation and string escaping required for bridge communications.

const std = @import("std");

/// This function handles characters that need escaping when embedding
/// strings in JavaScript, including newlines, quotes, and backslashes.
/// Essential for preventing syntax errors.
pub fn javascriptEscapeString(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var result = std.ArrayList(u8).init(allocator);
    for (input) |char| {
        switch (char) {
            '\n' => try result.appendSlice("\\n"),
            '\r' => try result.appendSlice("\\r"),
            '\t' => try result.appendSlice("\\t"),
            '\\' => try result.appendSlice("\\\\"),
            '"' => try result.appendSlice("\\\""),
            '\'' => try result.appendSlice("\\'"),
            else => try result.append(char),
        }
    }
    return result.toOwnedSlice();
}
