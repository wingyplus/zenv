const std = @import("std");
const ChildProcess = std.ChildProcess;
const dotenv = @import("./dotenv.zig");

// TODO: support custom .env file.
// TODO: support multiple .env files and make it overridable.

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    var allocator = gpa.allocator();

    var env_map = try dotenv.load(allocator, ".env");
    defer env_map.deinit();

    var args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var proc = ChildProcess.init(args[1..], allocator);
    proc.env_map = &env_map;
    proc.stdin = std.io.getStdIn();
    proc.stdout = std.io.getStdOut();
    proc.stderr = std.io.getStdErr();
    _ = try proc.spawnAndWait();
}

test {
    _ = @import("./dotenv.zig");
}
