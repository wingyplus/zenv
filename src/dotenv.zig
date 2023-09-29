const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const EnvMap = std.process.EnvMap;
const parser = @import("./dotenv/parser.zig");

pub const parse = parser.parse;

/// Load environment variables from the given path.
pub fn load(allocator: mem.Allocator, path: []const u8) !EnvMap {
    var file = try fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();
    var size = (try file.stat()).size;
    const content = try allocator.alloc(u8, size);
    defer allocator.free(content);
    const n = try file.readAll(content);
    std.debug.assert(n == size);
    return try parser.parse(allocator, content);
}

test load {
    var env = try load(std.testing.allocator, ".env");
    defer env.deinit();
    try std.testing.expectEqualStrings(env.get("A") orelse @panic("A not found"), "B");
}

test {
    _ = @import("./dotenv/parser.zig");
}
