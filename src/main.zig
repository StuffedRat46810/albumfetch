const std = @import("std");
const print = std.debug.print;
const album_file = @import("album.zig");
const build_options = @import("build_options");
const albums_utils = @import("album_utils.zig");
const config_utils = @import("config_utils.zig");
const log_file = @import("logger.zig");
const parser = @import("parser.zig");
const Album = album_file.Album;

pub const reset = "\x1b[0m";
pub const version = build_options.version;

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    var stdout_buf: [1024]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var logger = log_file.Logger.init(init.io, &stdout_buf, &stderr_buf);
    defer logger.flush() catch {};

    const raw_args = try init.minimal.args.toSlice(allocator);

    const args = parser.parse(raw_args, &logger) catch return;

    if (args.is_help or !args.has_args) {
        try logger.info(
            \\Usage: albumfetch [options]
            \\
            \\Options:
            \\  -h, --help        Display this help and exit.
            \\  -d, --daily       Display daily random album. 
            \\  -r, --random      Pick a random album instead of the daily one.
            \\  -v, --version     Output version information and exit.
            \\
        , .{});
        return;
    }

    if (args.is_version) {
        try logger.err("albumfetch version {s}\n", .{version});
        return;
    }

    const config_parsed = config_utils.Config.load(allocator) catch |err| {
        try logger.err("Fatal error: could not load or create config: {}\n", .{err});
        return;
    };
    defer config_parsed.deinit();
    const config = config_parsed.value;

    var albums = albums_utils.AlbumsList{};

    albums.init(config.albums, allocator) catch |err| {
        try logger.err("ERROR: albums.init() has failed: {}\n", .{err});
        return;
    };

    var res: ?Album = null;

    if (args.is_random) {
        res = try albums.getRandomAlbum();
    } else if (args.is_daily) {
        res = try albums.getDailyAlbum(null);
    }

    if (res) |album| {
        const is_tty = std.fs.File.stdout().isTty();

        try logger.printColored("Album:       ", config.theme.label, is_tty);
        try logger.printColored(album.album_name, config.theme.album, is_tty);
        try logger.info("\n", .{});

        try logger.printColored("Artist:      ", config.theme.label, is_tty);
        try logger.printColored(album.artist, config.theme.artist, is_tty);
        try logger.info("\n", .{});

        try logger.printColored("Genre:       ", config.theme.label, is_tty);
        try logger.printColored(album.genre, config.theme.genre, is_tty);
        try logger.info("\n", .{});

        try logger.printColored("Year:        ", config.theme.label, is_tty);
        try logger.printColored(album.year, config.theme.year, is_tty);
        try logger.info("\n", .{});
    }
}
