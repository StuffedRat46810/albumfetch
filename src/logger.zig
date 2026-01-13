const std = @import("std");
const color_utils = @import("color_utils.zig");
const Color = color_utils.Color;

// this struct exists as a workaround for printing to stdout or stdin.
// hopefully when zig 0.16 will release this problem will be solved.
pub const Logger = struct {
    stdout_buf: []u8,
    stderr_buf: []u8,
    stdout_writer: std.fs.File.Writer,
    stderr_writer: std.fs.File.Writer,

    pub fn init(stdout_buf: []u8, stderr_buf: []u8) Logger {
        return Logger{
            .stdout_buf = stdout_buf,
            .stderr_buf = stderr_buf,
            .stdout_writer = std.fs.File.stdout().writer(stdout_buf),
            .stderr_writer = std.fs.File.stderr().writer(stderr_buf),
        };
    }

    pub fn info(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
        const w: *std.Io.Writer = &self.stdout_writer.interface;
        try w.print(fmt, args);
    }

    pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) !void {
        const w: *std.Io.Writer = &self.stderr_writer.interface;
        try w.print(fmt, args);
        try w.print("\n", .{});
    }

    pub fn flush(self: *Logger) !void {
        try (&self.stdout_writer.interface).flush();
        try (&self.stderr_writer.interface).flush();
    }

    pub fn printColored(self: *Logger, text: []const u8, color: Color, is_tty: bool) !void {
        const w: *std.Io.Writer = &self.stdout_writer.interface;
        const color_code = color.toAnsi(is_tty);
        const reset = if (is_tty) Color.reset else "";

        try w.print("{s}{s}{s}", .{ color_code, text, reset });
    }
};
