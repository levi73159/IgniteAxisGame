const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const app = @import("app.zig");

const Object = @import("Display/Object.zig");
const Shader = @import("Display/Shader.zig");
const vector = @import("vector.zig");

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

    const window = app.createWindow("Main Window", vector.Vec2.init(window_width, window_height), null) catch {
        std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };

    app.setVsync(true);

    // zig fmt: off
    const positions = [_]f32{
        -0.5, -0.25,     // 0
        0.5, -0.25,      // 1
        0.5, 0.15,       // 2
        -0.5, 0.15,      // 3
    };

    const positions2 = [_]f32{ 
        -0.5, 0.15, 
        0.5, 0.15,
        0.2, 0.35, 
        -0.2, 0.45 };
    // zig fmt: on
    // _ = positions2;

    const indices = [_]u32{ 0, 1, 2, 2, 3, 0 };

    const layout = Object.Layout.init(&[1]Object.Attrib{.{ .size = 2 }});

    var rect = Object.init(null, &positions, &indices, layout);
    defer rect.deinit();

    var rect2 = Object.init(null, &positions2, &indices, layout);
    defer rect2.deinit();

    var color = app.Color.red;

    rect.setUniform("u_Color", .{ .color = app.Color.colorRGB(210, 155, 255) });

    try window.renderer.addObject(&rect);
    try window.renderer.addObject(&rect2);
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

        rect2.setUniform("u_Color", .{ .color = color });
        window.render();
    }
}
