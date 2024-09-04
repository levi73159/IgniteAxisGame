const std = @import("std");
const Shader = @import("Shader.zig");
const Object = @import("Object.zig");
const Color = @import("Color.zig");
const Window = @import("Window.zig");
const gl = @import("gl");
const glfw = @import("glfw");

const Self = @This();

objects: std.ArrayList(*Object), 
_parent: ?*const Window,

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{ 
        .objects = std.ArrayList(*Object).init(allocator), 
        ._parent = null,
    };
}

pub fn setParent(self: *Self, window: ?*const Window) void {
    self._parent = window;
}

pub fn deinit(self: Self) void {
    self.objects.deinit();
}

pub fn addObject(self: *Self, obj: *Object) !void {
    try self.objects.append(obj);
}

pub fn getObject(self: *const Self, index: usize) *Object {
    return &self.objects.items[index];
}

pub fn render(self: Self, window: *const Window, default_shader: *const Shader) void {
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
