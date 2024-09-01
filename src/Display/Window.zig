const glfw = @import("glfw");
const Vec2 = @import("../vector.zig").Vec2;
const Color = @import("Color.zig");

const Self = @This();

window_ctx: glfw.Window,
background_color: Color = Color.black,

/// return `error.WindowCreate` if fail
pub fn create(title: [*:0]const u8, size: Vec2) !Self {
    const window: glfw.Window = glfw.Window.create(@intFromFloat(size.x), @intFromFloat(size.y), title, null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 3,
        .context_version_minor = 3,
    }) orelse {
        return error.WindowCreate;
    };


    return .{ .window_ctx = window };
}

pub fn close(self: Self) void {
    self.window_ctx.setShouldClose(true);
    self.window_ctx.destroy();
}

pub fn getSize(self: Self) Vec2 {
    const size = self.window_ctx.getSize();
    return .{.x = @floatFromInt(size.width), .y = @floatFromInt(size.height)};
} 

pub fn shouldClose(self: Self) bool {
    return self.window_ctx.shouldClose();
}