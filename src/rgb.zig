const std = @import("std");


pub const RGB = struct {
    red: u8,
    green: u8,
    blue: u8,

    pub fn convertRGBA2RGB(self: *RGB, rgba: RGBA) void {
        self = rgba.rgb;
    }
};

pub const RGBA = struct {
    rgb: RGB,
    alpha: u8,
};

