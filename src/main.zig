const std = @import("std");
const fs = std.fs;
const ArrayList = std.ArrayList;
const ChildProcess = std.ChildProcess;
const dotenv = @import("./dotenv.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    var allocator = gpa.allocator();

    var env_map = try dotenv.load(allocator, ".env");
    defer env_map.deinit();

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var result = try ChildProcess.exec(.{ .allocator = allocator, .argv = args[1..], .env_map = &env_map });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);

    std.debug.print("{s}\n", .{result.stdout});
}

test {
    _ = @import("./dotenv.zig");
}
