const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const app = @import("app.zig");

const Object = @import("Display/Object.zig");
const Shader = @import("Display/Shader.zig");

const Allocator = std.mem.Allocator;


const window_width = 800;
const window_height = 600;

pub fn main() !void {
    // if (!glfw.init(.{})) {
    //     std.log.err("Failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
    //     std.process.exit(1);
    // }
    // defer glfw.terminate();
    app.init() catch |err| switch (err) {
        error.AlreadyInit => unreachable,
        error.GLFWInit => {
            std.log.err("Failed to init glfw: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        },
    };
    defer app.deinit();

    const window = app.createWindow("Main Window", .{.x = window_width, .y = window_height}) catch {
        std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };

    app.setVsync(true);

    // zig fmt: off
    const positions = [_]f32{
        -0.5, -0.5,     // 0
        0.5, -0.5,      // 1
        0.5, 0.5,       // 2
        -0.5, 0.5,      // 3
    };
    // zig fmt: on

    const indices = [_]u32 { 0, 1, 2, 2, 3, 0 };


    const shader = Shader.init(app.getAllocator(), "default");
    defer shader.deinit();

    const layout = Object.Layout.init(&[1]Object.Attrib { .{ .size = 2 } });

    // TODO: make a better Object Init function
    const rect = Object.init(&shader, &positions, &indices, layout);
    defer rect.deinit();

    var color = app.Color.red;

    try window.renderer.addObject(rect); 
    while (!window.shouldClose()) {
        if (window.getKeyPress(.right) or window.getKeyPress(.up)) {
            color.r +|= 1;
            color.g +|= 1;
            color.b +|= 1;
        } else if (window.getKeyPress(.left) or window.getKeyPress(.down)) {
            color.r -|= 1;
            color.g -|= 1;
            color.b -|= 1;
        }

        shader.setUniformColor("u_Color", color);
        window.render();
    }
}
