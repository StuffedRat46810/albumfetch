const std = @import("std");
const print = std.debug.print;
const album_file = @import("album.zig");
const albums_utils = @import("album_fetch_utils.zig");
const Album = album_file.Album;
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    errdefer arena.deinit();
    const allocator = arena.allocator();
    var albums = albums_utils.AlbumsList{};
    albums.init(allocator) catch |err| {
        print("ERROR: albums.init() has failed: {}\n", .{err});
        return;
    };

    const res: Album = albums.getDailyAlbum() catch |err| {
        print("ERROR: getDailyAlbum() has failed: {}\n", .{err});
        return;
    };
    std.debug.print(
        \\Album:   {s}
        \\Artists: {s}
        \\Genre:   {s}
        \\Year:    {s}
        \\
    ,
        .{ res.album_name, res.artist, res.genre, res.year },
    );
}
