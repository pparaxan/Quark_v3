const std = @import("std");
const Quark = @import("../quark.zig");
const frontend = Quark.frontend;
const url_mime = @import("mime.zig").URIMimeType;

fn escapeJsonString(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var escaped = std.ArrayList(u8).init(allocator);
    defer escaped.deinit();

    for (input) |char| {
        switch (char) {
            '"' => try escaped.appendSlice("\\\""),
            '\\' => try escaped.appendSlice("\\\\"),
            '\n' => try escaped.appendSlice("\\n"),
            '\r' => try escaped.appendSlice("\\r"),
            '\t' => try escaped.appendSlice("\\t"),
            else => try escaped.append(char),
        }
    }

    return escaped.toOwnedSlice();
}

pub fn URIProtocolHandler(seq: [*c]const u8, req: [*c]const u8, arg: ?*anyopaque) callconv(.C) void {
    const quark_ptr: *Quark.Quark = @ptrCast(@alignCast(arg.?));
    const req_str = std.mem.span(req);

    var path: []const u8 = req_str;
    if (std.mem.startsWith(u8, req_str, "[\"") and std.mem.endsWith(u8, req_str, "\"]")) { // this works
        path = req_str[2 .. req_str.len - 2];
    }

    if (frontend.get(path)) |resource_data| {
        const mime_type = url_mime(path);

        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        defer _ = gpa.deinit();
        const allocator = gpa.allocator();

        const escaped_data = escapeJsonString(allocator, resource_data) catch {
            _ = Quark.quark_webview.webview_return(quark_ptr.webview, seq, 1, "{\"success\":false}");
            return;
        };
        defer allocator.free(escaped_data);

        var response_buf: [8192]u8 = undefined;

        const response_len = std.fmt.bufPrint(&response_buf, "{{\"success\":true,\"data\":\"{s}\",\"mimeType\":\"{s}\"}}", .{ escaped_data, mime_type }) catch {
            _ = Quark.quark_webview.webview_return(quark_ptr.webview, seq, 1, "{\"success\":false}");
            return;
        };
        response_buf[response_len.len] = 0;

        const ret = Quark.quark_webview.webview_return(quark_ptr.webview, seq, 0, &response_buf[0]);
        if (ret != Quark.quark_webview.WEBVIEW_ERROR_OK) {
            std.debug.print("webview_return error: {}\n", .{ret}); // replace this with an error!
        }
    } else {
        _ = Quark.quark_webview.webview_return(quark_ptr.webview, seq, 1, "{\"success\":false}");
    }
}
