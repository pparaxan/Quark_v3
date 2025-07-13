const std = @import("std");

pub fn getWindowsSDKPath(allocator: std.mem.Allocator) ![]const u8 {
    const program_files = if (@import("builtin").target.cpu.arch == .x86) "C:\\Program Files\\" else "C:\\Program Files (x86)\\";
    const sdk_base = program_files ++ "Windows Kits\\10\\Include\\";
    const sdk_version = try findSDKVersion(sdk_base);
    return std.fmt.allocPrint(allocator, "{s}{s}", .{ sdk_base, sdk_version });
}

fn findSDKVersion(path: []const u8) ![]const u8 {
    const allocator = std.heap.page_allocator;
    var dir = try std.fs.openDirAbsolute(path, .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();
    var latest_version: ?[]const u8 = null;
    var max_version: u32 = 0;

    while (try iter.next()) |entry| {
        if (entry.kind == .directory and std.mem.startsWith(u8, entry.name, "10.0")) {
            const version = try parseSDKVersion(entry.name);
            if (version > max_version) {
                max_version = version;
                latest_version = try allocator.dupe(u8, entry.name);
            }
        }
    }

    return latest_version orelse @panic("No valid SDK version found");
}

fn parseSDKVersion(version_str: []const u8) !u32 {
    var parts = std.mem.splitScalar(u8, version_str, '.');
    _ = parts.next();
    _ = parts.next();

    const patch = try std.fmt.parseInt(u32, parts.next() orelse return error.InvalidFormat, 10);
    return patch;
}
