const std = @import("std");
const mem = std.mem;
const testing = std.testing;
const EnvMap = std.process.EnvMap;

const spaces = " \t";

const ParseError = error{IllegalCharacter};

fn validateKey(key: []const u8) ![]const u8 {
    var i: usize = 0;
    while (i < key.len) : (i += 1) {
        switch (key[i]) {
            'A'...'Z', 'a'...'z', '0'...'9', '_' => continue,
            else => return ParseError.IllegalCharacter,
        }
    }
    return key;
}

const Quote = enum { single, double };

fn determineQuote(ch: u8) ?Quote {
    switch (ch) {
        '\'' => return Quote.single,
        '"' => return Quote.double,
        else => return null,
    }
}

fn hasSpacesPrefix(value: []const u8) bool {
    var found_any_ch = false;
    for (value) |ch| {
        if (ch == ' ' and !found_any_ch) {
            return true;
        }
    }
    return false;
}

fn parseValue(value: []const u8) ![]const u8 {
    if (hasSpacesPrefix(value)) {
        return ParseError.IllegalCharacter;
    }
    if (determineQuote(value[0])) |beginQuote| {
        if (determineQuote(value[value.len - 1])) |endQuote| {
            // begin and end quote should be the same.
            if (beginQuote != endQuote) {
                return ParseError.IllegalCharacter;
            }
            return value[1..(value.len - 1)];
        }
    }
    return value;
}

pub fn parse(allocator: mem.Allocator, content: []const u8) !EnvMap {
    var map = EnvMap.init(allocator);
    var iter = mem.split(u8, content, "\n");
    while (iter.next()) |line| {
        if (mem.indexOf(u8, line, "=")) |offset| {
            // TODO: key should match RegExp.
            const key = try validateKey(mem.trimLeft(u8, line[0..offset], spaces));
            const value = try parseValue(mem.trimRight(u8, line[(offset + 1)..line.len], spaces));
            try map.put(key, value);
        }
    }
    return map;
}

test "parse" {
    const dot_env =
        \\K=V
        \\  K2=V2
        \\K3=V3    
        \\K4='V4'
        \\K5="V5"
        \\
    ;

    var env = try parse(testing.allocator, dot_env);
    defer env.deinit();

    try testing.expect(env.count() == 5);

    try testing.expectEqualStrings(env.get("K") orelse @panic("K must present"), "V");
    try testing.expectEqualStrings(env.get("K2") orelse @panic("K2 must present"), "V2");
    try testing.expectEqualStrings(env.get("K3") orelse @panic("K3 must present"), "V3");
    try testing.expectEqualStrings(env.get("K4") orelse @panic("K4 must present"), "V4");
    try testing.expectEqualStrings(env.get("K5") orelse @panic("K5 must present"), "V5");
}

test "parse error" {
    const dot_env =
        \\K=   V
    ;

    try testing.expectError(ParseError.IllegalCharacter, parse(testing.allocator, dot_env));
}
