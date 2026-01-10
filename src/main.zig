const std = @import("std");
const print = std.debug.print;
const album_file = @import("album.zig");
const albums_utils = @import("album_fetch_utils.zig");
const Album = album_file.Album;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var albums = albums_utils.AlbumsList{};
    try albums.init(allocator);
    defer albums.deinit();

    const res: Album = try albums.getRandomAlbum();
    print("Album: {s}\nArtists: {s}\nGenre: {s}\nYear: {s}\n", .{ res.album_name, res.artist, res.genre, res.year });
}
