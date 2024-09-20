const za = @import("zalgebra");
const glfw = @import("glfw");
const std = @import("std");

const Allocator = std.mem.Allocator;
const Key = glfw.Key;
const Color = @import("Color.zig");
const Shader = @import("Shader.zig");
const Camera = @import("Camera.zig");

const app = @import("../app.zig");

const Self = @This();
pub const Renderer = @import("Renderer.zig");

contex: glfw.Window,
renderer: Renderer,
background_color: Color = Color.black,

// private
_default_shader: Shader,

/// return `error.WindowCreate` if fail
///
/// If `default_shader` is null will use the 'default' by default, must be called by app
pub fn create(allocator: Allocator, title: [*:0]const u8, size: app.Size) !Self {
    const window: glfw.Window = glfw.Window.create(size.width, size.height, title, null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 3,
        .context_version_minor = 3,
    }) orelse {
        return error.WindowCreate;
    };

    // zig fmt: off
    return Self { 
        .contex = window, 
        .renderer = Renderer.init(allocator), 
        ._default_shader = undefined // the app will set that
    };
    // zig fmt: on
}

pub fn getProjectionMatrix(self: Self) za.Mat4 {
    const window_size = self.getSize();
    return za.orthographic(0, @as(f32, @floatFromInt(window_size.width)), @as(f32, @floatFromInt(window_size.height)), 0, -1, 1);
}

pub fn setDefaultShader(self: *Self, name: []const u8) void {
    self._default_shader = Shader.init(app.allocator(), name);
}

pub fn close(self: *Self) void {
    self.contex.setShouldClose(true);
    self.contex.destroy();
    self.renderer.deinit();
    self._default_shader.deinit();
}

pub fn getSize(self: Self) app.Size {
    return self.contex.getSize();
}

pub fn shouldClose(self: Self) bool {
    return self.contex.shouldClose();
}

pub fn getKeyPress(self: Self, key: Key) bool {
    const action = self.contex.getKey(key);
    return action == .press;
}

pub fn getKeyRelease(self: Self, key: Key) bool {
    const action = self.contex.getKey(key);
    return action == .release;
}

pub fn getDefaultShader(self: *Self) *Shader {
    return &self._default_shader;
}

// wraper so we dont have to accsess
pub inline fn setTitle(self: Self, title: [:0]const u8) void {
    self.contex.setTitle(title.ptr);
}

// Update window
pub fn update(self: *Self) void {
    const size = self.getSize();
    app.setViewport(size.width, size.height);

    self.contex.swapBuffers();
    glfw.pollEvents();
}


// Calls `Renderer.render()`
pub fn render(self: *Self, cam: Camera) void {
    self.renderer.render(cam, self, self.getDefaultShader());
}
