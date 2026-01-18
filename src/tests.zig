const std = @import("std");
const testing = std.testing;

const color_utils = @import("color_utils.zig");
const album = @import("album.zig");
const album_utils = @import("album_utils.zig");
const time_utils = @import("time.zig");

// --- Color Utils Tests ---
test "Color Utils - ANSI codes" {
    try testing.expectEqualStrings("", color_utils.Color.red.toAnsi(false));
    try testing.expectEqualStrings("\x1b[31m", color_utils.Color.red.toAnsi(true));
    try testing.expectEqualStrings("\x1b[0m", color_utils.Color.reset);
}

test "Theme - Default Values" {
    const theme = color_utils.Theme{};
    try testing.expectEqual(color_utils.Color.cyan, theme.label);
    try testing.expectEqual(color_utils.Color.white, theme.album);
}

// --- Album Struct Tests ---
test "Album Struct - Initialization" {
    const a = album.Album{
        .artist = "Pink Floyd",
        .album_name = "The Dark Side of the Moon",
        .genre = "Progressive Rock",
        .year = "1973",
    };
    try testing.expectEqualStrings("Pink Floyd", a.artist);
    try testing.expectEqualStrings("The Dark Side of the Moon", a.album_name);
}

// --- Time Utils Tests ---
test "Time Utils - Offset Validity" {
    const offset = time_utils.getLocalTimeOffset();
    const seconds_in_day = 86400;
    try testing.expect(offset >= -seconds_in_day);
    try testing.expect(offset <= seconds_in_day);
}

// --- Album Utils Tests ---

fn createDummyJson(filename: []const u8, content: []const u8) !void {
    const file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    try file.writeAll(content);
}

test "Album Utils - Init with Invalid File" {
    // We use an arena here for consistency, though not strictly needed for the error case
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = album_utils.AlbumsList{};
    const err = list.init("non_existent_file.json", allocator);
    try testing.expectError(error.FileNotFound, err);
}

test "Album Utils - Parsing and Retrieval" {
    // USE ARENA: This frees all memory (including the internal file buffer) at the end of the block
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_filename = "test_albums_parsing.json";
    const json_content =
        \\[
        \\  ["Test Album 1", "Artist 1", "Rock", "2001"],
        \\  ["Test Album 2", "Artist 2", "Jazz", "2002"],
        \\  ["Test Album 3", "Artist 3", "Pop", "2003"]
        \\]
    ;

    try createDummyJson(test_filename, json_content);
    defer std.fs.cwd().deleteFile(test_filename) catch {};

    var list = album_utils.AlbumsList{};
    // No need to call list.deinit() because the arena handles everything

    try list.init(test_filename, allocator);

    try testing.expect(list.size.? == 3);

    const a1 = list.getNthAlbum(0);
    try testing.expectEqualStrings("Test Album 1", a1.album_name);
}

test "Album Utils - Random Album" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_filename = "test_albums_random.json";
    const json_content =
        \\[
        \\  ["Unique Album", "Artist", "Genre", "2020"]
        \\]
    ;

    try createDummyJson(test_filename, json_content);
    defer std.fs.cwd().deleteFile(test_filename) catch {};

    var list = album_utils.AlbumsList{};
    try list.init(test_filename, allocator);

    const rand_album = try list.getRandomAlbum();
    try testing.expectEqualStrings("Unique Album", rand_album.album_name);
}

test "Album Utils - Daily Album Consistency" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const test_filename = "test_albums_daily.json";
    const json_content =
        \\[
        \\  ["A1", "B1", "C1", "1"],
        \\  ["A2", "B2", "C2", "2"],
        \\  ["A3", "B3", "C3", "3"]
        \\]
    ;

    try createDummyJson(test_filename, json_content);
    defer std.fs.cwd().deleteFile(test_filename) catch {};

    var list = album_utils.AlbumsList{};
    try list.init(test_filename, allocator);

    const mock_time: i64 = 1600000000;

    const daily1 = try list.getDailyAlbum(mock_time);
    const daily2 = try list.getDailyAlbum(mock_time);

    try testing.expectEqualStrings(daily1.album_name, daily2.album_name);
}
