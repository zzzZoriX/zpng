const std = @import("std");
const Io = std.Io;

const png_signature = [_]u8{
    137, 80, 78, 71, 13, 10, 26, 10
};

pub const PNGError = error{
    InvalidPNG,
    InvalidChunk,
    NoAllocator,
};

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

    pub fn extractIDAT(self: *PNG) !void {
        if(self.allocator == null) 
            return PNGError.NoAllocator;

        if(self.buffer.len < 8 or !std.mem.eql(u8, self.buffer[0..8], &png_signature))
            return PNGError.InvalidPNG;

        var result: std.ArrayList(u8) = .empty;
        errdefer if(self.allocator) |allocator| 
            result.deinit(allocator);

        var offset: usize = 8;

        while(offset < self.buffer.len) {
            if(self.buffer.len - offset < 12)
                return PNGError.InvalidChunk;

            const data_length: usize = std.mem.readInt(u32, self.buffer[offset..][0..4], .big);
            const chunk_type = self.buffer[offset + 4..offset + 8];

            offset += 8;

            if(data_length > self.buffer.len - offset - 4)
                return PNGError.InvalidChunk;

            const data = self.buffer[offset..offset + data_length];

            if(std.mem.eql(u8, chunk_type, "IDAT")) {
                if(self.allocator) |allocator|
                    try result.appendSlice(allocator, data);
            }

            offset += data_length + 4;

            if(std.mem.eql(u8, chunk_type, "IEND"))
                break;
        }

        if(self.allocator) |allocator|
            self.idat_buffer = try result.toOwnedSlice(allocator);
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

    std.debug.print("buffer len: {}\nidat_buffer len: {}\n", .{png.buffer.len, png.idat_buffer.len});
}

test "png test 2" {
    const io = testing.io;
    const allocator = testing.allocator;

    var png: PNG = .{};
    try png.load("test/t3st.png", io, allocator, 10 * 1024 * 1024);
    defer png.deinit();

    try png.extractIDAT();

    std.debug.print("buffer len: {}\nidat_buffer len: {}\n", .{png.buffer.len, png.idat_buffer.len});
}

test "png test 3" {
    const io = testing.io;
    const allocator = testing.allocator;

    var png: PNG = .{};
    try png.load("test/test2.png", io, allocator, 10 * 1024 * 1024);
    defer png.deinit();

    try png.extractIDAT();

    std.debug.print("buffer len: {}\nidat_buffer len: {}\n", .{png.buffer.len, png.idat_buffer.len});
}