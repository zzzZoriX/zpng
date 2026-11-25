const std = @import("std");
const Io = std.Io;


pub const PNG = struct {
    buffer: []u8 = &.{},
    idat_buffer: []u8 = &.{},
    scale: ?struct { y: i32, x: i32 } = null,
    allocator: ?std.mem.Allocator = null,

    pub fn load(self: *PNG, path: []const u8, io: Io, allocator: std.mem.Allocator, limit: usize) !void {
        const new_buffer = try Io.Dir.cwd().readFileAlloc(io, path, allocator, .limited(limit));

        if (self.allocator) |old_allocator| {
            old_allocator.free(self.buffer);
            old_allocator.free(self.idat_buffer);
        }

        self.buffer = new_buffer;
        self.allocator = allocator;
    }

    pub fn deinit(self: *PNG) void {
        if (self.allocator) |allocator| {
            allocator.free(self.buffer);
            allocator.free(self.idat_buffer);
        }

        self.* = .{};
    }

};

const testing = std.testing;

test "png test 1" {
    const io = testing.io;
    const allocator = testing.allocator;

    var png: PNG = .{};
    try png.load("test/test.png", io, allocator, 10 * 1024 * 1024);
    defer png.deinit();

    try png.extractIDAT();

    std.debug.print("buffer len: {}\nidat_buffer len: {}\n", .{ png.buffer.len, png.idat_buffer.len });
}

test "png test 2" {
    const io = testing.io;
    const allocator = testing.allocator;

    var png: PNG = .{};
    try png.load("test/t3st.png", io, allocator, 10 * 1024 * 1024);
    defer png.deinit();

    try png.extractIDAT();

    std.debug.print("buffer len: {}\nidat_buffer len: {}\n", .{ png.buffer.len, png.idat_buffer.len });
}

test "png test 3" {
    const io = testing.io;
    const allocator = testing.allocator;

    var png: PNG = .{};
    try png.load("test/test2.png", io, allocator, 10 * 1024 * 1024);
    defer png.deinit();

    try png.extractIDAT();

    std.debug.print("buffer len: {}\nidat_buffer len: {}\n", .{ png.buffer.len, png.idat_buffer.len });
}
