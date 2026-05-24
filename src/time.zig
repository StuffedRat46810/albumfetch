const std = @import("std");
const c = @cImport({
    @cInclude("time.h");
});

pub fn getLocalTimeOffset(io: std.Io) i64 {
    const now = std.Io.Clock.real.now(io).toSeconds();
    var timer = @as(c.time_t, @intCast(now)); //convert the current time into a c_long

    const local_t = c.localtime(&timer);

    return @as(i64, local_t.*.tm_gmtoff);
}
