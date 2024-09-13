const std = @import("std");
const gl = @import("gl");
const za = @import("zalgebra");

const Texture = @import("../Display/Texture.zig");
const Shader = @import("../Display/Shader.zig");
const Object = @import("../Display/Object.zig");
const Renderer = @import("../Display/Renderer.zig");
const Self = @This();

pub const GameObject = @import("GameObject.zig");
pub const SceneObject = @import("SceneObject.zig");

// A scene is struct with Array of SceneObject which is a basic structure whith a GameObject and data
name: [*:0]const u8,
objects: []SceneObject, // heap allocated
allocator: std.mem.Allocator,

/// panics if OutOfMemory
pub fn init(allocator: std.mem.Allocator, name: [*:0]const u8, objects: []const SceneObject) Self {
    return Self{ 
        .name = name, 
        .objects = allocator.dupe(SceneObject, objects) catch std.debug.panic("Not Enough Memory To Dup", .{}),
        .allocator = allocator,
    };
}

pub fn load(self: *Self, renderer: *Renderer) !void {
    for (self.objects) |*obj| {
        try obj.load(renderer, self.objects);
    }
}

// updates all the scene game objects if have any
pub fn update(self: *Self) void {
    for (self.objects) |*obj| {
        if (obj.object != null) {
            obj.object.?.update();
        } 
    }
}

// unload the scene
pub fn unload(self: *Self) void {
    for (self.objects) |*obj| {
        obj.deinit();
    }
}

pub fn reload(self: *Self, renderer: *Renderer) !void {
    for (self.objects) |*obj| {
        obj.deinit();
        try obj.load(renderer);
    }
}

pub fn deinit(self: *const Self) void {
    self.allocator.free(self.objects);
}
