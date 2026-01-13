const std = @import("std");

pub const Color = enum {
    white,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    gray,
    dim,

    pub fn toAnsi(self: Color, is_tty: bool) []const u8 {
        if (!is_tty) return "";

        return switch (self) {
            .white => "",
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .magenta => "\x1b[35m",
            .cyan => "\x1b[36m",
            .gray => "\x1b[37m",
            .dim => "\x1b[2m",
        };
    }

    pub const reset = "\x1b[0m";
};

pub const Theme = struct {
    label: Color = .cyan,
    album: Color = .white,
    artist: Color = .white,
    genre: Color = .white,
    year: Color = .white,
};
