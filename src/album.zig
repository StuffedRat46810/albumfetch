const std = @import("std");

pub const Album = struct {
    artist: []const u8,
    album_name: []const u8,
    genre: []const u8,
    year: []const u8,
};
