const std = @import("std");

const gl = @import("gl");
const zigimg = @import("zigimg");

const core = @import("../core.zig");

const Texture = @This();

pub const FilterMode = enum {
    nearest,
    linear,
};

pub const Options = struct {
    filepath: []const u8,
    filter_mode: FilterMode = .linear,
};

pub const RawOptions = struct {
    // TODO: multiple formats
    /// RGBA8 format
    data: []u32,

    width: usize,
    height: usize,
};

// TODO: should remove this opengl specific id
// for something platfrom agnostic
// leave for when renderer rewrite to vulkan/d3d12
id: c_uint,
width: usize,
height: usize,

pub fn init(options: Options) !Texture {
    var image = try zigimg.Image.fromFilePath(core.allocator, options.filepath);
    defer image.deinit();

    const internal_format: u32 = switch (image.pixelFormat()) {
        .rgb24 => gl.RGB8,
        .rgba32 => gl.RGBA8,
        else => @panic("Texture format not supported"),
    };
    const data_format: u32 = switch (image.pixelFormat()) {
        .rgb24 => gl.RGB,
        .rgba32 => gl.RGBA,
        else => @panic("Texture format not supported"),
    };

    var tex_id: gl.uint = undefined;
    gl.GenTextures(1, (&tex_id)[0..1]);
    gl.BindTexture(gl.TEXTURE_2D, tex_id);

    gl.TexStorage2D(gl.TEXTURE_2D, 1, internal_format, @intCast(image.width), @intCast(image.height));

    const filter_mode: c_int = switch (options.filter_mode) {
        .linear => gl.LINEAR,
        .nearest => gl.NEAREST,
    };

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filter_mode);

    switch (image.pixels) {
        .rgb24 => |data| gl.TexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, @intCast(image.width), @intCast(image.height), data_format, gl.UNSIGNED_BYTE, @ptrCast(data)),
        .rgba32 => |data| gl.TexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, @intCast(image.width), @intCast(image.height), data_format, gl.UNSIGNED_BYTE, @ptrCast(data)),
        else => @panic("Texture format not supported"),
    }

    return Texture{
        .id = tex_id,
        .width = image.width,
        .height = image.height,
    };
}

pub fn initRaw(options: RawOptions) Texture {
    std.debug.assert(options.width * options.height == options.data.len);

    const internal_format: u32 = gl.RGBA8;
    const data_format: u32 = gl.RGBA;

    var tex_id: gl.uint = undefined;
    gl.GenTextures(1, (&tex_id)[0..1]);
    gl.BindTexture(gl.TEXTURE_2D, tex_id);

    gl.TexStorage2D(gl.TEXTURE_2D, 1, internal_format, @intCast(options.width), @intCast(options.height));

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

    gl.TexSubImage2D(gl.TEXTURE_2D, 0, 0, 0, @intCast(options.width), @intCast(options.height), data_format, gl.UNSIGNED_BYTE, @ptrCast(options.data));

    return Texture{
        .id = tex_id,
        .width = options.width,
        .height = options.height,
    };
}

pub fn deinit(self: *Texture) void {
    gl.DeleteTextures(1, (&self.id)[0..1]);
}
