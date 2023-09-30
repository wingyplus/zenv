const std = @import("std");
const process = std.process;
const ChildProcess = std.ChildProcess;
const EnvMap = std.process.EnvMap;
const dotenv = @import("./dotenv.zig");

// TODO: support custom .env file.
// TODO: support multiple .env files and make it overridable.
// TODO: use exit code from child process.

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    var allocator = gpa.allocator();

    var parent_env_map = try process.getEnvMap(allocator);
    defer parent_env_map.deinit();

    var env_map = try dotenv.load(allocator, ".env");
    defer env_map.deinit();

    try mergeEnv(&parent_env_map, env_map);

    var args = try process.argsAlloc(allocator);
    defer process.argsFree(allocator, args);

    var proc = ChildProcess.init(args[1..], allocator);
    proc.env_map = &parent_env_map;
    proc.stdin = std.io.getStdIn();
    proc.stdout = std.io.getStdOut();
    proc.stderr = std.io.getStdErr();
    _ = try proc.spawnAndWait();
}

// Merge env from right to left.
fn mergeEnv(left: *EnvMap, right: EnvMap) !void {
    var iter = right.iterator();
    while (iter.next()) |entry| {
        try left.put(entry.key_ptr.*, entry.value_ptr.*);
    }
}

test {
    _ = @import("./dotenv.zig");
}
