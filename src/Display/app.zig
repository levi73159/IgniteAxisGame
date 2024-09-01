const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const Vec2 = @import("../vector.zig").Vec2;

pub const Window = @import("Window.zig");
pub const Color = @import("Color.zig");

const log = std.log.scoped(.app);

var been_init = false;
var primary_window: ?Window = null;
const opengl_proc: glfw.GLProc = undefined;

fn glGetProcAddress(_: glfw.GLProc, proc: [:0]const u8) ?gl.binding.FunctionPointer {
    return glfw.getProcAddress(proc);
}

pub const InitError = error{ AlreadyInit, GLFWInit };

pub fn init() InitError!void {
    if (been_init) return error.AlreadyInit;

    if (!glfw.init(.{})) {
        return error.GLFWInit;
    }

    been_init = true;
}

pub fn deinit() void {
    if (primary_window) |win| {
        win.close();
    }

    glfw.terminate();
}

pub fn createWindow(title: [*:0]const u8, size: Vec2) !*const Window {
    if (!been_init)
        try init();

    primary_window = try Window.create(title, size);
    glfw.makeContextCurrent(primary_window.?.window_ctx);

    gl.loadExtensions(opengl_proc, glGetProcAddress) catch return error.EntryPointNotFound;
    log.info("Window {s}, Version: {s}\n", .{title, gl.getString(.version) orelse "null"});

    gl.viewport(0, 0, @intFromFloat(size.x), @intFromFloat(size.y));
    return &primary_window.?;
}

pub fn setWindow(window: Window) void {
    primary_window = window;
    glfw.makeContextCurrent(primary_window.?.window_ctx);
    const size = window.getSize();
    gl.viewport(0, 0, @intFromFloat(size.x), @intFromFloat(size.y));
}

pub fn getWindow() ?*const Window {
    return if (primary_window) |win| &win else null;
}

pub fn clear() void {
    if (primary_window) |win| {
        const color = win.background_color.getRealColor();
        gl.clearColor(color.r, color.g, color.b, color.a);
    } else {
        gl.clearColor(0, 0, 0, 1);
    }
        
    gl.clear(.{ .color = true });
}