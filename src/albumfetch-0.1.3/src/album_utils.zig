const std = @import("std");
pub const Album = struct {
    artist: []const u8,
    album_name: []const u8,
    genre: []const u8,
    year: []const u8,
};
const AlbumErrors = error{
    file_error,
    json_error,
    null_json,
};
pub const AlbumsList = struct {
    file_buffer: ?[]u8 = null,
    parsed_data: ?std.json.Parsed([][4][]const u8) = null,
    albums: ?[][4][]const u8 = null,
    size: ?usize = null,

    pub fn init(self: *AlbumsList, json_path: ?[]const u8, allocator: std.mem.Allocator, io: std.Io) !void {
        const path = json_path orelse return AlbumErrors.null_json;
        if (path.len == 0) {
            return AlbumErrors.null_json;
        }

        const cwd = std.Io.Dir.cwd();

        // replaced all manual file operations with buffer
        const buffer = try cwd.readFileAlloc(io, path, allocator, .unlimited); // no file size limit
        errdefer allocator.free(buffer);

        self.file_buffer = buffer;
        const AlbumData = [][4][]const u8;

        self.parsed_data = try std.json.parseFromSlice(AlbumData, allocator, buffer, .{});
        self.albums = self.parsed_data.?.value;
        self.size = self.parsed_data.?.value.len;
    }

    pub fn getRandomAlbum(self: *AlbumsList, io: std.Io) !Album {
        // create an 8-byte array to hold raw randomness
        var seed_bytes: [8]u8 = undefined;
        io.random(std.mem.asBytes(&seed_bytes));
        const seed = std.mem.readInt(u64, &seed_bytes, .little);
        var prng: std.Random.DefaultPrng = .init(seed);
        const rand = prng.random();
        const index = rand.intRangeLessThan(usize, 0, self.size.?);
        return self.getNthAlbum(index);
    }
    pub fn getNthAlbum(self: *AlbumsList, n: usize) Album {
        const temp = self.albums.?[n];
        return Album{
            .album_name = temp[0],
            .artist = temp[1],
            .genre = temp[2],
            .year = temp[3],
        };
    }
    pub fn getDailyAlbum(self: *AlbumsList, manual_now: ?i64, io: std.Io) !Album {
        const now = manual_now orelse std.Io.Clock.real.now(io).toSeconds();

        const seconds_in_day = 86400;
        const daysSinceEpoch = @as(u64, @intCast(@divFloor(now, seconds_in_day)));

        var prng = std.Random.DefaultPrng.init(daysSinceEpoch);
        const rand = prng.random();

        // Ensure the size is vaild before picking the index
        const max_idx = self.size orelse return error.AlbumNotInitialized;
        const index = rand.intRangeLessThan(usize, 0, max_idx);

        return self.getNthAlbum(index);
    }
    pub fn deinit(self: *AlbumsList, allocator: std.mem.Allocator) void {
        if (self.parsed_data) |p| {
            p.deinit();
        }
        if (self.file_buffer) |b| {
            allocator.free(b);
        }
    }
};
