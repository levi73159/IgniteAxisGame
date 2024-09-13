const std = @import("std");
const gl = @import("gl");
const glfw = @import("glfw");

const Shader = @import("Shader.zig");
const Object = @import("Object.zig");
const Color = @import("Color.zig");
const Window = @import("Window.zig");
const Camera = @import("Camera.zig");

const Self = @This();

allocator: std.mem.Allocator,
objects: std.ArrayList(*Object),

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .objects = std.ArrayList(*Object).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: Self) void {
    for (self.objects.items) |obj| {
        obj.deinit();
        self.allocator.destroy(obj);
    }
    self.objects.deinit();
}

/// must be heap allocation, should be called by `Object.create` insted and obj should be created using the `Renderer.allocator`
pub fn addObject(self: *Self, obj: *Object) !void {
    obj.id = self.objects.items.len;
    try self.objects.append(obj);
}

pub fn getObject(self: *const Self, index: usize) *Object {
    return &self.objects.items[index];
}

pub fn removeIndex(self: *Self, index: usize, deinit_obj: bool) void {
    const removed_obj = self.objects.orderedRemove(index);
    if (deinit_obj) {
        removed_obj.deinit();
    }

    // and now we want to free object
    self.allocator.destroy(removed_obj);

    // and now we got to shift the object id to left
    for (self.objects.items, 0..) |obj, obj_id| {
        obj.id = obj_id; // update all the obj rendering ids 
    }
}

pub fn render(self: Self, camera: Camera, window: *const Window, default_shader: *Shader) void {
    const real_bgcolor = window.background_color.getRealColor();
    gl.clearColor(real_bgcolor.r, real_bgcolor.g, real_bgcolor.b, real_bgcolor.a);
    gl.clear(.{ .color = true });

    for (self.objects.items) |object| {
        const mvp = window.getProjectionMatrix().mul(camera.getTransform()).mul(object.getTransform());
        object.setUniform("MVP", .{ .mat4 = mvp });
        if (object.shader == null) {
            object.drawShader(default_shader);
        } else {
            object.draw();
        }
    }
}
