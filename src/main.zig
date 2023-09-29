const std = @import("std");
const fs = std.fs;
const dotenv = @import("./dotenv.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    var allocator = gpa.allocator();

    var env = try dotenv.load(allocator, ".env");
    defer env.deinit();

    var iter = env.iterator();
    while (iter.next()) |entry| {
        std.debug.print("{s}={s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
}

test {
    _ = @import("./dotenv.zig");
}
