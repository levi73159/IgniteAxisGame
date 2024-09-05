const std = @import("std");
const Shader = @import("Shader.zig");
const Object = @import("Object.zig");
const Color = @import("Color.zig");
const Window = @import("Window.zig");
const gl = @import("gl");
const glfw = @import("glfw");

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
        self.allocator.destroy(obj);
    }
    self.objects.deinit();
}

/// must be heap allocation, should be called by `Object.create` insted
pub fn addObject(self: *Self, obj: *Object) !void {
    try self.objects.append(obj);
}

/// copies the object and return ref to it
/// 
/// NOTE: does not need to be freed, `Renderer` frees all objects, notice that this behiavor may change in later versions
pub fn addObjectCopy(self: *Self, obj: Object) !*Object {
    const object_ptr = try self.allocator.create(Object);
    object_ptr.* = obj;
    try self.objects.append(object_ptr);
    return object_ptr;
}

pub fn getObject(self: *const Self, index: usize) *Object {
    return &self.objects.items[index];
}

pub fn render(self: Self, window: *const Window, default_shader: *Shader) void {
    const real_bgcolor = window.background_color.getRealColor();
    gl.clearColor(real_bgcolor.r, real_bgcolor.g, real_bgcolor.b, real_bgcolor.a);
    gl.clear(.{ .color = true });

    for (self.objects.items) |object| {
        if (object.shader == null) {
            object.drawShader(default_shader);
        } else {
            object.draw();
        }
    }

    window.contex.swapBuffers();
    glfw.pollEvents();
}
