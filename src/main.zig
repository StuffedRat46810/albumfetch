const std = @import("std");
const print = std.debug.print;
const album_file = @import("album.zig");
const albums_utils = @import("album_fetch_utils.zig");
const config_utils = @import("config_utils.zig");
const Album = album_file.Album;

const Command = enum {
    random,
    daily,
    help,
};

pub fn main() !void {
    const args = std.os.argv;
    if (std.os.argv.len <= 1) {
        // this message needs some work
        print("ERROR: albumfetch requires parameters to work", .{});
        return;
    }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    errdefer arena.deinit();
    const allocator = arena.allocator();

    const config = config_utils.Config.load(allocator) catch |err| {
        print("Fatal error: could not load or create config: {}\n", .{err});
        return;
    };

    var albums = albums_utils.AlbumsList{};

    albums.init(config.albums, allocator) catch |err| {
        print("ERROR: albums.init() has failed: {}\n", .{err});
        return;
    };
    const input = std.mem.span(args[1]);
    const cmd = std.meta.stringToEnum(Command, input) orelse {
        print("Invalid command: {s}\n", .{input});
        return;
    };
    if (cmd == .help) {
        print("Usage: albumfetch [daily|random|help]\n", .{});
        return;
    }
    const res: Album = switch (cmd) {
        .daily => albums.getDailyAlbum() catch |err| {
            print("error: getDailyAlbum() has failed: {}\n", .{err});
            return;
        },
        .random => albums.getRandomAlbum() catch |err| {
            print("error: getRandomAlbum() has failed: {}\n", .{err});
            return;
        },
        else => unreachable,
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
