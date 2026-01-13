const std = @import("std");
const color_utils = @import("color_utils.zig");
const default_data = @embedFile("albums.json");

const Color = color_utils.Color;
const Theme = color_utils.Theme;

pub const Config = struct {
    albums: []const u8,
    theme: Theme = .{},

    pub fn load(allocator: std.mem.Allocator) !std.json.Parsed(Config) {
        const path = try ensureConfigExists(allocator);
        defer allocator.free(path); // this might cause problems later

        const file = try std.fs.openFileAbsolute(path, .{ .mode = .read_only });
        defer file.close(); // this might cause problems later

        const size = try file.getEndPos();
        const buffer = try allocator.alloc(u8, size);
        // defer allocator.free(buffer);
        _ = try file.readAll(buffer);

        return try std.json.parseFromSlice(Config, allocator, buffer, .{
            .ignore_unknown_fields = true,
        });
    }

    fn ensureConfigExists(allocator: std.mem.Allocator) ![]u8 {
        // retrieves user's home directory
        const home = try std.process.getEnvVarOwned(allocator, "HOME");
        defer allocator.free(home);

        // builds ~/.config/albumfetch
        const config_dir_path = try std.fs.path.join(allocator, &[_][]const u8{ home, ".config", "albumfetch" });
        const config_file_path = try std.fs.path.join(allocator, &[_][]const u8{ config_dir_path, "config.json" });
        const default_albums_path = try std.fs.path.join(allocator, &[_][]const u8{ config_dir_path, "albums.json" });

        std.fs.cwd().makePath(config_dir_path) catch |err| {
            if (err != error.PathAlreadyExists) return err;
        };

        std.fs.accessAbsolute(default_albums_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                const new_file = try std.fs.createFileAbsolute(default_albums_path, .{});
                defer new_file.close();
                try new_file.writeAll(default_data);
            } else return err;
        };

        std.fs.accessAbsolute(config_file_path, .{}) catch |err| {
            if (err == error.FileNotFound) {
                const f = try std.fs.createFileAbsolute(config_file_path, .{});
                defer f.close();
                const template = try std.fmt.allocPrint(allocator,
                    \\{{
                    \\  "albums": "{s}",
                    \\  "theme": {{
                    \\      "label": "cyan",
                    \\      "album": "none",
                    \\      "artist": "none",
                    \\      "genre": "none",
                    \\      "year": "none",
                    \\}}
                , .{default_albums_path});
                try f.writeAll(template);
            } else return err;
        };
        return config_file_path;
    }
};
