const std = @import("std");
const testing = std.testing;

const color_utils = @import("color_utils.zig");
const album_utils = @import("album_utils.zig");

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
    const a = album_utils.Album{
        .artist = "Pink Floyd",
        .album_name = "The Dark Side of the Moon",
        .genre = "Progressive Rock",
        .year = "1973",
    };
    try testing.expectEqualStrings("Pink Floyd", a.artist);
    try testing.expectEqualStrings("The Dark Side of the Moon", a.album_name);
}

// --- Album Utils Tests ---

// Updated to use the new std.Io.Dir interface!
fn createDummyJson(dir: std.Io.Dir, io: std.Io, filename: []const u8, content: []const u8) !void {
    const file = try dir.createFile(io, filename, .{});
    defer file.close(io);
    _ = try file.writePositionalAll(io, content, 0);
}

test "Album Utils - Init with Invalid File" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Grab the global test Io instance
    const io = std.testing.io;

    var list = album_utils.AlbumsList{};
    const err = list.init("non_existent_file.json", allocator, io);
    try testing.expectError(error.FileNotFound, err);
}

test "Album Utils - Parsing and Retrieval" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const io = std.testing.io;

    // 1. Create a self-cleaning temporary directory
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const test_filename = "test_albums_parsing.json";
    const json_content =
        \\[
        \\  ["Test Album 1", "Artist 1", "Rock", "2001"],
        \\  ["Test Album 2", "Artist 2", "Jazz", "2002"],
        \\  ["Test Album 3", "Artist 3", "Pop", "2003"]
        \\]
    ;

    // 2. Write the file inside the temp directory
    try createDummyJson(tmp.dir, io, test_filename, json_content);

    // 3. Resolve the absolute path of the temp directory so album_utils can find it natively
    const temp_path = try tmp.dir.realPathFileAlloc(io, ".", allocator);
    const abs_file_path = try std.fs.path.join(allocator, &[_][]const u8{ temp_path, test_filename });

    var list = album_utils.AlbumsList{};
    try list.init(abs_file_path, allocator, io);
    try testing.expect(list.size.? == 3);

    const a1 = list.getNthAlbum(0);
    try testing.expectEqualStrings("Test Album 1", a1.album_name);
}

test "Album Utils - Random Album" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const test_filename = "test_albums_random.json";
    const json_content =
        \\[
        \\  ["Unique Album", "Artist", "Genre", "2020"]
        \\]
    ;

    try createDummyJson(tmp.dir, io, test_filename, json_content);

    const temp_path = try tmp.dir.realPathFileAlloc(io, ".", allocator);
    const abs_file_path = try std.fs.path.join(allocator, &[_][]const u8{ temp_path, test_filename });

    var list = album_utils.AlbumsList{};
    try list.init(abs_file_path, allocator, io);

    // Pass `io` to your updated random method
    const rand_album = try list.getRandomAlbum(io);
    try testing.expectEqualStrings("Unique Album", rand_album.album_name);
}

test "Album Utils - Daily Album Consistency" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const test_filename = "test_albums_daily.json";
    const json_content =
        \\[
        \\  ["A1", "B1", "C1", "1"],
        \\  ["A2", "B2", "C2", "2"],
        \\  ["A3", "B3", "C3", "3"]
        \\]
    ;

    try createDummyJson(tmp.dir, io, test_filename, json_content);

    const temp_path = try tmp.dir.realPathFileAlloc(io, ".", allocator);
    const abs_file_path = try std.fs.path.join(allocator, &[_][]const u8{ temp_path, test_filename });

    var list = album_utils.AlbumsList{};
    try list.init(abs_file_path, allocator, io);

    const mock_time: i64 = 1600000000;

    // Pass `io` down the chain
    const daily1 = try list.getDailyAlbum(mock_time, io);
    const daily2 = try list.getDailyAlbum(mock_time, io);

    try testing.expectEqualStrings(daily1.album_name, daily2.album_name);
}
