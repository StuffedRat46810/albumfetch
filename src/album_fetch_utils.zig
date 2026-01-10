const std = @import("std");
const album_file = @import("album.zig");
const AlbumErrors = error{
    file_error,
    json_error,
};
pub const AlbumsList = struct {
    // these 2 specific attributes make sure the data doesn't turn into garbage
    raw_json: ?[]u8 = null,
    allocator: ?std.mem.Allocator = null,

    parsed_data: ?std.json.Parsed([][4][]const u8) = null,
    albums: ?[][4][]const u8 = null,
    size: ?usize = null,

    pub fn init(self: *AlbumsList, allocator: std.mem.Allocator) !void {
        self.allocator = allocator;

        const file = try std.fs.cwd().readFileAlloc(allocator, "albums.json", 1024 * 1024);
        self.raw_json = file;

        self.parsed_data = try std.json.parseFromSlice([][4][]const u8, allocator, file, .{});
        self.albums = self.parsed_data.?.value;
        self.size = self.parsed_data.?.value.len;
    }

    fn getRandomNumber(size: ?usize) !usize {
        var seed: u64 = 0;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        var prng: std.Random.DefaultPrng = .init(seed);
        const rand = prng.random();
        return rand.intRangeLessThan(usize, 0, size.?);
    }

    pub fn getRandomAlbum(self: *AlbumsList) !album_file.Album {
        if (self.albums == null or self.size == 0) return error.EmptyList;
        const randIndex = try getRandomNumber(self.size.?);
        const temp = self.albums.?[randIndex];
        return album_file.Album{
            .album_name = temp[0],
            .artist = temp[1],
            .genre = temp[2],
            .year = temp[3],
        };
    }

    pub fn deinit(self: *AlbumsList) void {
        // deletes the json object
        if (self.parsed_data) |p| {
            p.deinit();
        }
        // deletes the file buffer.
        // turns out deleting the file buffer in the init function fucks up the program real bad
        if (self.raw_json) |raw| {
            if (self.allocator) |alloc| {
                alloc.free(raw);
            }
        }
    }
};
