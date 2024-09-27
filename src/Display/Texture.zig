const std = @import("std");
const gl = @import("gl");
const zigimg = @import("zigimg");

const Image = zigimg.Image;

const Self = @This();

// map of all the slots used up
var used_slots: u32 = 0;

renderer_id: u32,
filepath: []const u8,
slot: u32,
uses: *u32, // to specify how much this texture is being uses

// usefull info we will probably need
width: usize,
height: usize,

pub fn init(allocator: std.mem.Allocator, path: []const u8) !Self {
    return initParameters(allocator, path, .repeat, .repeat);
}

pub fn initParameters(allocator: std.mem.Allocator, path: []const u8, wrap_s: gl.TextureParameterType(.wrap_s), wrap_t: gl.TextureParameterType(.wrap_t)) !Self {
    var image = try Image.fromFilePath(allocator, path);
    defer image.deinit();

    const slot = used_slots;
    used_slots += 1;

    const texture_id = gl.genTexture();
    gl.activeTexture(gl.TextureUnit.unit(slot));
    gl.bindTexture(texture_id, .@"2d"); // and never unbinding

    gl.textureParameter(texture_id, .min_filter, gl.TextureParameterType(.min_filter).nearest);
    gl.textureParameter(texture_id, .mag_filter, gl.TextureParameterType(.mag_filter).nearest);
    gl.textureParameter(texture_id, .wrap_s, wrap_s);
    gl.textureParameter(texture_id, .wrap_t, wrap_t);

    gl.textureImage2D(.@"2d", 0, .rgba8, image.width, image.height, .rgba, .unsigned_byte, image.pixels.asConstBytes().ptr);
    gl.generateMipmap(.@"2d");

    const uses_ptr = try allocator.create(u32);
    uses_ptr.* = 0;

    return Self{
        .renderer_id = @intFromEnum(texture_id),
        .filepath = path,
        .slot = slot,
        .width = image.width,
        .height = image.height,
        .uses = uses_ptr,
    };
}

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    if (self.uses.* > 1) {
        self.uses.* -= 1;
        return;
    }

    gl.deleteTexture(@enumFromInt(self.renderer_id));
    allocator.destroy(self.uses);
}

pub fn bind(self: Self) void {
    gl.activeTexture(gl.TextureUnit.unit(self.slot));
    gl.bindTexture(@enumFromInt(self.renderer_id), .@"2d");
}

pub fn unbind() void {
    gl.bindTexture(.invalid, .@"2d");
}
