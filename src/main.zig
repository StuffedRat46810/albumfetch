const std = @import("std");
const print = std.debug.print;
const album_file = @import("album.zig");
const albums_utils = @import("album_utils.zig");
const config_utils = @import("config_utils.zig");
const log_file = @import("logger.zig");
const clap = @import("clap");
const Album = album_file.Album;

pub const cyan = "\x1b[36m";
pub const reset = "\x1b[0m";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    errdefer arena.deinit();
    const allocator = arena.allocator();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var logger = log_file.Logger.init(&stdout_buf, &stderr_buf);
    defer logger.flush() catch {};

    const params = comptime clap.parseParamsComptime(
        \\-h, --help        Display this help and exit.
        \\-d, --daily       Display daily random album. 
        \\-r, --random      Pick a random album instead of the daily one.
        \\-v, --version     Output version information and exit.
    );

    var argsRes = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .allocator = allocator,
    }) catch |err| {
        try logger.err("Error parsing arguments: {}\n", .{err});
        return;
    };
    defer argsRes.deinit();

    const args_count = std.os.argv.len;

    if (argsRes.args.help != 0 or args_count == 1) {
        try logger.info("Usage: albumfetch [options]\n", .{});
        try clap.help(&logger.stderr_writer.interface, clap.Help, &params, .{});
        return;
    }

    if (argsRes.args.version != 0) {
        try logger.err("albumfetch version 0.0.1\n", .{});
        return;
    }

    const config = config_utils.Config.load(allocator) catch |err| {
        try logger.err("Fatal error: could not load or create config: {}\n", .{err});
        return;
    };

    var albums = albums_utils.AlbumsList{};

    albums.init(config.albums, allocator) catch |err| {
        try logger.err("ERROR: albums.init() has failed: {}\n", .{err});
        return;
    };

    var res: ?Album = null;

    if (argsRes.args.random != 0) {
        res = try albums.getRandomAlbum();
    } else if (argsRes.args.daily != 0) {
        res = try albums.getDailyAlbum(null);
    }
    try logger.info(
        \\{s:<12}{s} {s}
        \\{s:<12}{s} {s}
        \\{s:<12}{s} {s}
        \\{s:<12}{s} {s}
        \\
    ,
        .{ cyan, "Album:", reset, res.?.album_name, cyan, "Artists:", reset, res.?.artist, cyan, "Genre:", reset, res.?.genre, cyan, "Year:", reset, res.?.year },
    );
}
