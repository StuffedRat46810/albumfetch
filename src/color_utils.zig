const std = @import("std");

pub const Color = enum {
    none,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    dim,

    pub fn toAnsi(self: Color, is_tty: bool) []const u8 {
        if (!is_tty) return "";

        return switch (self) {
            .none => "",
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .magenta => "\x1b[35m",
            .cyan => "\x1b[36m",
            .white => "\x1b[37;1m",
            .dim => "\x1b[2m",
        };
    }

    pub const reset = "\x1b[0m";
};

pub const Theme = struct {
    label: Color = .cyan,
    album: Color = .none,
    artist: Color = .none,
    genre: Color = .none,
    year: Color = .none,
};
