const std = @import("std");
const album_file = @import("album.zig");
const AlbumErrors = error{
    file_error,
    json_error,
};
pub const AlbumsList = struct {
    // these 2 specific attributes make sure the data doesn't turn into garbage

    parsed_data: ?std.json.Parsed([][4][]const u8) = null,
    albums: ?[][4][]const u8 = null,
    size: ?usize = null,

    pub fn init(self: *AlbumsList, allocator: std.mem.Allocator) !void {

        // const file = try std.fs.cwd().readFileAlloc(allocator, "albums.json", 1024 * 1024);
        const json_path = "/Users/alon/Repo/zig/albumfetch-zig/albums.json";
        const file = try std.fs.openFileAbsolute(json_path, .{ .mode = .read_only });
        defer file.close();
        const file_size = try file.getEndPos();
        const buffer = try allocator.alloc(u8, file_size);
        errdefer allocator.free(buffer);
        const bytes_read = try file.readAll(buffer);
        if (bytes_read != file_size) return error.FileReadIncomplete;

        const AlbumData = [][4][]const u8;

        self.parsed_data = try std.json.parseFromSlice(AlbumData, allocator, buffer, .{});
        self.albums = self.parsed_data.?.value;
        self.size = self.parsed_data.?.value.len;
    }

    // these two function will probably move into their own struct.

    pub fn getRandomAlbum(self: *AlbumsList) !album_file.Album {
        var seed: u64 = 0;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        var prng: std.Random.DefaultPrng = .init(seed);
        const rand = prng.random();
        const index = rand.intRangeLessThan(usize, 0, self.size.?);
        return try self.getNthAlbum(index);
    }
    pub fn getNthAlbum(self: *AlbumsList, n: usize) !album_file.Album {
        const temp = self.albums.?[n];
        return album_file.Album{
            .album_name = temp[0],
            .artist = temp[1],
            .genre = temp[2],
            .year = temp[3],
        };
    }
    pub fn getDailyAlbum(self: *AlbumsList) !album_file.Album {
        const now = std.time.timestamp();
        const daysSinceEpoch = @as(u64, @intCast(@divFloor(now, 86400)));
        var prng = std.Random.DefaultPrng.init(daysSinceEpoch);
        const rand = prng.random();
        const index = rand.intRangeLessThan(usize, 0, self.size.?);
        return try self.getNthAlbum(index);
    }
};
