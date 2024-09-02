const Allocator = @import("std").mem.Allocator;
const glfw = @import("glfw");
const Vec2 = @import("../vector.zig").Vec2;
const Color = @import("Color.zig");
const Key = glfw.Key;

const Self = @This();
pub const Renderer = @import("Renderer.zig");

contex: glfw.Window,
renderer: Renderer,
background_color: Color = Color.black,

/// return `error.WindowCreate` if fail
pub fn create(allocator: Allocator, title: [*:0]const u8, size: Vec2) !Self {
    const window: glfw.Window = glfw.Window.create(@intFromFloat(size.x), @intFromFloat(size.y), title, null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 3,
        .context_version_minor = 3,
    }) orelse {
        return error.WindowCreate;
    };

    return Self{ .contex = window, .renderer = Renderer.init(allocator) };
}

pub fn close(self: Self) void {
    self.contex.setShouldClose(true);
    self.contex.destroy();
    self.renderer.deinit();
}

pub fn getSize(self: Self) Vec2 {
    const size = self.contex.getSize();
    return .{ .x = @floatFromInt(size.width), .y = @floatFromInt(size.height) };
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

// Calls `Renderer.render()`
pub fn render(self: *const Self) void {
    self.renderer.render(self);
}