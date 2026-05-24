const std = @import("std");
const color_utils = @import("color_utils.zig");
const default_data = @embedFile("albums.json");

const Color = color_utils.Color;
const Theme = color_utils.Theme;

pub const Config = struct {
    albums: []const u8,
    theme: Theme = .{},

    pub fn load(allocator: std.mem.Allocator, home: []const u8, io: std.Io) !std.json.Parsed(Config) {
        const path = try ensureConfigExists(allocator, home, io);
        defer allocator.free(path); // this might cause problems later
        const cwd = std.Io.Dir.cwd();

        const file = try cwd.openFile(io, path, .{ .mode = .read_only });
        defer file.close(io); // this might cause problems later

        const size = try file.length(io);
        const buffer = try allocator.alloc(u8, size);
        // defer allocator.free(buffer);
        _ = try file.readPositionalAll(io, buffer, 0);

        return try std.json.parseFromSlice(Config, allocator, buffer, .{
            .ignore_unknown_fields = true,
        });
    }

    fn ensureConfigExists(allocator: std.mem.Allocator, home: []const u8, io: std.Io) ![]u8 {
        // builds ~/.config/albumfetch
        const config_dir_path = try std.fs.path.join(allocator, &[_][]const u8{ home, ".config", "albumfetch" });
        defer allocator.free(config_dir_path);
        const config_file_path = try std.fs.path.join(allocator, &[_][]const u8{ config_dir_path, "config.json" });
        const default_albums_path = try std.fs.path.join(allocator, &[_][]const u8{ config_dir_path, "albums.json" });
        defer allocator.free(default_albums_path);

        const cwd = std.Io.Dir.cwd();
        cwd.createDirPath(io, config_dir_path) catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };

        cwd.access(io, default_albums_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                const new_file = try cwd.createFile(io, default_albums_path, .{});
                defer new_file.close(io);
                _ = try new_file.writePositionalAll(io, default_data, 0);
            } else return err;
        };

        cwd.access(io, config_file_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                const f = try cwd.createFile(io, config_file_path, .{});
                defer f.close(io);
                const template = try std.fmt.allocPrint(allocator,
                    \\{{
                    \\  "albums": "{s}",
                    \\  "theme": {{
                    \\      "label": "cyan",
                    \\      "album": "white",
                    \\      "artist": "white",
                    \\      "genre": "white",
                    \\      "year": "white"
                    \\  }}
                    \\}}
                , .{default_albums_path});
                defer allocator.free(template);
                try f.writePositionalAll(io, template, 0);
            } else return err;
        };
        return config_file_path;
    }
};
