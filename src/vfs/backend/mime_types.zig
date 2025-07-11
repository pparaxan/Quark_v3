const std = @import("std");

const MimeMapping = struct {
    extensions: []const []const u8,
    mime_type: []const u8,
};

const MIME_DATABASE = [_]MimeMapping{
    .{ .extensions = &.{".aac"}, .mime_type = "audio/aac" },
    .{ .extensions = &.{".abw"}, .mime_type = "application/x-abiword" },
    .{ .extensions = &.{".apng"}, .mime_type = "image/apng" },
    .{ .extensions = &.{".arc"}, .mime_type = "application/x-freearc" },
    .{ .extensions = &.{".avif"}, .mime_type = "image/avif" },
    .{ .extensions = &.{".avi"}, .mime_type = "video/x-msvideo" },
    .{ .extensions = &.{".azw"}, .mime_type = "application/vnd.amazon.ebook" },
    .{ .extensions = &.{".bin"}, .mime_type = "application/octet-stream" },
    .{ .extensions = &.{".bmp"}, .mime_type = "image/bmp" },
    .{ .extensions = &.{".bz"}, .mime_type = "application/x-bzip" },
    .{ .extensions = &.{".bz2"}, .mime_type = "application/x-bzip2" },
    .{ .extensions = &.{".cda"}, .mime_type = "application/x-cdf" },
    .{ .extensions = &.{".csh"}, .mime_type = "application/x-csh" },
    .{ .extensions = &.{".css"}, .mime_type = "text/css" },
    .{ .extensions = &.{".csv"}, .mime_type = "text/csv" },
    .{ .extensions = &.{".doc"}, .mime_type = "application/msword" },
    .{ .extensions = &.{".docx"}, .mime_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document" },
    .{ .extensions = &.{".eot"}, .mime_type = "application/vnd.ms-fontobject" },
    .{ .extensions = &.{".epub"}, .mime_type = "application/epub+zip" },
    .{ .extensions = &.{".gz"}, .mime_type = "application/gzip" },
    .{ .extensions = &.{".gif"}, .mime_type = "image/gif" },
    .{ .extensions = &.{ ".htm", ".html" }, .mime_type = "text/html" },
    .{ .extensions = &.{".ico"}, .mime_type = "image/vnd.microsoft.icon" },
    .{ .extensions = &.{".ics"}, .mime_type = "text/calendar" },
    .{ .extensions = &.{".jar"}, .mime_type = "application/java-archive" },
    .{ .extensions = &.{ ".jpeg", ".jpg" }, .mime_type = "image/jpeg" },
    .{ .extensions = &.{ ".js", ".mjs", ".cjs" }, .mime_type = "text/javascript" },
    .{ .extensions = &.{".json"}, .mime_type = "application/json" },
    .{ .extensions = &.{".jsonld"}, .mime_type = "application/ld+json" },
    .{ .extensions = &.{ ".mid", ".midi" }, .mime_type = "audio/midi" },
    .{ .extensions = &.{ ".mp3", ".mpeg" }, .mime_type = "audio/mpeg" },
    .{ .extensions = &.{".mp4"}, .mime_type = "video/mp4" },
    .{ .extensions = &.{".mpkg"}, .mime_type = "application/vnd.apple.installer+xml" },
    .{ .extensions = &.{".odp"}, .mime_type = "application/vnd.oasis.opendocument.presentation" },
    .{ .extensions = &.{".ods"}, .mime_type = "application/vnd.oasis.opendocument.spreadsheet" },
    .{ .extensions = &.{".odt"}, .mime_type = "application/vnd.oasis.opendocument.text" },
    .{ .extensions = &.{".oga"}, .mime_type = "audio/ogg" },
    .{ .extensions = &.{".ogv"}, .mime_type = "video/ogg" },
    .{ .extensions = &.{".ogx"}, .mime_type = "application/ogg" },
    .{ .extensions = &.{".opus"}, .mime_type = "audio/opus" },
    .{ .extensions = &.{".otf"}, .mime_type = "font/otf" },
    .{ .extensions = &.{".png"}, .mime_type = "image/png" },
    .{ .extensions = &.{".pdf"}, .mime_type = "application/pdf" },
    .{ .extensions = &.{".php"}, .mime_type = "application/x-httpd-php" },
    .{ .extensions = &.{".ppt"}, .mime_type = "application/vnd.ms-powerpoint" },
    .{ .extensions = &.{".pptx"}, .mime_type = "application/vnd.openxmlformats-officedocument.presentationml.presentation" },
    .{ .extensions = &.{".rar"}, .mime_type = "application/vnd.rar" },
    .{ .extensions = &.{".rtf"}, .mime_type = "application/rtf" },
    .{ .extensions = &.{".sh"}, .mime_type = "application/x-sh" },
    .{ .extensions = &.{".svg"}, .mime_type = "image/svg+xml" },
    .{ .extensions = &.{".tar"}, .mime_type = "application/x-tar" },
    .{ .extensions = &.{ ".tif", ".tiff" }, .mime_type = "image/tiff" },
    .{ .extensions = &.{".ts"}, .mime_type = "application/typescript" },
    .{ .extensions = &.{".ttf"}, .mime_type = "font/ttf" },
    .{ .extensions = &.{".txt"}, .mime_type = "text/plain" },
    .{ .extensions = &.{".vsd"}, .mime_type = "application/vnd.visio" },
    .{ .extensions = &.{".wav"}, .mime_type = "audio/wav" },
    .{ .extensions = &.{".weba"}, .mime_type = "audio/webm" },
    .{ .extensions = &.{".webm"}, .mime_type = "video/webm" },
    .{ .extensions = &.{".webp"}, .mime_type = "image/webp" },
    .{ .extensions = &.{".woff"}, .mime_type = "font/woff" },
    .{ .extensions = &.{".woff2"}, .mime_type = "font/woff2" },
    .{ .extensions = &.{".xhtml"}, .mime_type = "application/xhtml+xml" },
    .{ .extensions = &.{".xls"}, .mime_type = "application/vnd.ms-excel" },
    .{ .extensions = &.{".xlsx"}, .mime_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" },
    .{ .extensions = &.{".xml"}, .mime_type = "application/xml" },
    .{ .extensions = &.{".xul"}, .mime_type = "application/vnd.mozilla.xul+xml" },
    .{ .extensions = &.{".zip"}, .mime_type = "application/zip" },
    .{ .extensions = &.{".7z"}, .mime_type = "application/x-7z-compressed" },
};

pub fn detect_mime_type(filename: []const u8) []const u8 {
    for (MIME_DATABASE) |mapping| {
        for (mapping.extensions) |extensions| {
            if (std.mem.endsWith(u8, filename, extensions)) {
                return mapping.mime_type;
            }
        }
    }
    return "application/octet-stream";
}
