const std = @import("std");
const gl = @import("gl");
const zigimg = @import("zigimg");

const Image = zigimg.Image;

const Self = @This();

renderer_id: u32,
filepath: []const u8,
slot: u32,
// image: Image, // Right now we do not want to store the image

pub fn init(allocator: std.mem.Allocator, path: []const u8, slot: u32) !Self {
    return initParameters(allocator, path, slot, .clamp_to_edge, .clamp_to_edge);
}

pub fn initParameters(allocator: std.mem.Allocator, path: []const u8, slot: u32, wrap_s: gl.TextureParameterType(.wrap_s), wrap_t: gl.TextureParameterType(.wrap_t)) !Self {
    var image = try Image.fromFilePath(allocator, path);
    defer image.deinit();

    const texture_id = gl.genTexture();
    gl.activeTexture(gl.TextureUnit.unit(slot));
    gl.bindTexture(texture_id, .@"2d");

    gl.textureParameter(texture_id, .min_filter, gl.TextureParameterType(.min_filter).nearest);
    gl.textureParameter(texture_id, .mag_filter, gl.TextureParameterType(.mag_filter).nearest);
    gl.textureParameter(texture_id, .wrap_s, wrap_s);
    gl.textureParameter(texture_id, .wrap_t, wrap_t);

    gl.textureImage2D(.@"2d", 0, .rgba8, image.width, image.height, .rgba, .unsigned_byte, image.pixels.asConstBytes().ptr);
    gl.generateMipmap(.@"2d");

    return Self{
        .renderer_id = @intFromEnum(texture_id),
        .filepath = path,
        .slot = slot,
    };
}

pub fn deinit(self: Self) void {
    gl.deleteTexture(@enumFromInt(self.renderer_id));
}

pub fn bind(self: Self) void {
    gl.activeTexture(gl.TextureUnit.unit(self.slot));
    gl.bindTexture(@enumFromInt(self.renderer_id), .@"2d");
}

pub fn unbind() void {
    gl.bindTexture(.invalid, .@"2d");
}
