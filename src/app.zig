const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const math = @import("zalgebra");
const Shader = @import("Display/Shader.zig");

pub const Window = @import("Display/Window.zig");
pub const Color = @import("Display/Color.zig");
pub const Object = @import("Display/Object.zig");
pub const Key = glfw.Key;

const log = std.log.scoped(.app);

var been_init = false;
var opengl_init = false;
var primary_window: ?Window = null;
const opengl_proc: glfw.GLProc = undefined;

var app_gpa: std.heap.GeneralPurposeAllocator(.{}) = undefined;

var default_layout: Object.Layout = undefined;

pub const Size = glfw.Window.Size;

fn glGetProcAddress(_: glfw.GLProc, proc: [:0]const u8) ?gl.binding.FunctionPointer {
    return glfw.getProcAddress(proc);
}

pub const InitError = error{ AlreadyInit, GLFWInit };

pub fn init() InitError!void {
    if (been_init) return error.AlreadyInit;

    if (!glfw.init(.{})) {
        return error.GLFWInit;
    }
    app_gpa = std.heap.GeneralPurposeAllocator(.{}){};

    been_init = true;
}

fn initOpenGL() !void {
    if (opengl_init) return error.AlreadyInit;
    opengl_init = true;

    // initlizing opengl
    gl.loadExtensions(opengl_proc, glGetProcAddress) catch return error.EntryPointNotFound;

    // enabling blending
    gl.enable(.blend);  
    gl.blendFunc(.src_alpha, .one_minus_src_alpha);

    // setting default layout
    default_layout = Object.Layout.init(&[2]Object.Attrib { .{ .size = 2 }, .{ .size = 2}, });
}

pub fn deinit() void {
    if (primary_window != null) {
        primary_window.?.close();
    }

    const denit_status = app_gpa.deinit();
    if (denit_status == .leak) log.warn("Mem leak detected", .{});
    glfw.terminate();
}

pub fn allocator() std.mem.Allocator {
    return app_gpa.allocator();
}

pub fn defaultLayout() *const Object.Layout {
    return &default_layout;
}

pub fn setVsync(vsync: bool) void {
    glfw.swapInterval(if (vsync) 1 else 0);
}

pub fn setViewport(width: usize, height: usize) void {
    gl.viewport(0, 0, width, height);
}

pub fn createWindow(title: [*:0]const u8, width: u32, height: u32, default_shader: ?[]const u8) !*Window {
    if (!been_init)
        try init();

    primary_window = try Window.create(allocator(), title, .{.width = width, .height = height});
    glfw.makeContextCurrent(primary_window.?.contex);

    if (!opengl_init)
        try initOpenGL();
    log.info("Window {s}, Version: {s}\n", .{ title, gl.getString(.version) orelse "null" });

    setViewport(width, height);

    primary_window.?.setDefaultShader(default_shader orelse "default");

    return &primary_window.?;
}

pub fn setWindow(window: Window) void {
    primary_window = window;
    glfw.makeContextCurrent(primary_window.?.contex);
    const size = window.getSize();
    gl.viewport(0, 0, @intFromFloat(size.x), @intFromFloat(size.y));
}

pub fn getWindow() ?*const Window {
    return if (primary_window) |win| &win else null;
}
