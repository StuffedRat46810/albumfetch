const std = @import("std");
const print = std.debug.print;
const album_file = @import("album.zig");
const albums_utils = @import("album_utils.zig");
const config_utils = @import("config_utils.zig");
const clap = @import("clap");
const Album = album_file.Album;

const Command = enum {
    random,
    daily,
    help,
};

pub fn main() !void {
    // const args = std.os.argv;
    // if (std.os.argv.len <= 1) {
    //     // this message needs some work
    //     print("ERROR: albumfetch requires parameters to work", .{});
    //     return;
    // }
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    errdefer arena.deinit();
    const allocator = arena.allocator();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help        Display this help and exit.
        \\-d, --daily       Display daily random album. 
        \\-r, --random      Pick a random album instead of the daily one.
        \\-v, --version     Output version information and exit.
    );

    var argsRes = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .allocator = allocator,
    }) catch |err| {
        print("Error parsing arguments: {}\n", .{err});
        return;
    };
    defer argsRes.deinit();

    const args_count = std.os.argv.len;

    if (argsRes.args.help != 0 or args_count == 1) {
        var stderr_buf: [1024]u8 = undefined;
        var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);
        const stderr = &stderr_writer.interface;

        try stderr.print("Usage: albumfetch [options]\n", .{});
        // i got a gut feeling this line doesn't work
        try clap.help(stderr, clap.Help, &params, .{});
        try stderr.flush();
        return;
    }

    if (argsRes.args.version != 0) {
        print("albumfetch version 0.0.1\n", .{});
        return;
    }

    const config = config_utils.Config.load(allocator) catch |err| {
        print("Fatal error: could not load or create config: {}\n", .{err});
        return;
    };

    var albums = albums_utils.AlbumsList{};

    albums.init(config.albums, allocator) catch |err| {
        print("ERROR: albums.init() has failed: {}\n", .{err});
        return;
    };

    var res: ?Album = null;

    if (argsRes.args.random != 0) {
        res = try albums.getRandomAlbum();
    } else if (argsRes.args.daily != 0) {
        res = try albums.getDailyAlbum(null);
    }
    // const res: Album = switch (cmd) {
    //     .daily => albums.getDailyAlbum(null) catch |err| {
    //         print("error: getDailyAlbum() has failed: {}\n", .{err});
    //         return;
    //     },
    //     .random => albums.getRandomAlbum() catch |err| {
    //         print("error: getRandomAlbum() has failed: {}\n", .{err});
    //         return;
    //     },
    //     else => unreachable,
    // };
    std.debug.print(
        \\Album:   {s}
        \\Artists: {s}
        \\Genre:   {s}
        \\Year:    {s}
        \\
    ,
        .{ res.?.album_name, res.?.artist, res.?.genre, res.?.year },
    );
}
