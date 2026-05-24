const std = @import("std");
const log_file = @import("logger.zig");

pub const ParsedArgs = struct {
    is_help: bool = false,
    is_daily: bool = false,
    is_random: bool = false,
    is_version: bool = false,
    has_args: bool = false,
};

pub fn parse(args: []const []const u8, logger: *log_file.Logger) !ParsedArgs {
    var result = ParsedArgs{};
    for (args[1..]) |arg| {
        result.has_args = true;

        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            result.is_help = true;
        } else if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--daily")) {
            result.is_daily = true;
        } else if (std.mem.eql(u8, arg, "-r") or std.mem.eql(u8, arg, "--random")) {
            result.is_random = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            result.is_version = true;
        } else {
            try logger.err("Unknown argument: {s}\n", .{arg});
            try logger.info("Run with -h or --help for usage.\n", .{});
            return error.UnknownArgument;
        }
    }
    return result;
}
