const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const app = @import("app.zig");

const Object = @import("Display/Object.zig");
const Shader = @import("Display/Shader.zig");
const Texture = @import("Display/Texture.zig");
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

    window.background_color = app.Color.white;

    app.setVsync(true);

    // zig fmt: off
    const positions = [_]f32{
        -0.5, -0.5, 0, 1,// 0
        0.5, -0.5, 1, 1, // 1
        0.5, 0.5, 1, 0,  // 2
        -0.5, 0.5, 0, 0 // 3
    };

    // const positions2 = [_]f32{ 
    //     -0.5, 0.15, 0, 1, 0, 
    //     0.5, 0.15, 0, 1, 1,
    //     0.2, 0.35, 0, 1, 0, 
    //     -0.2, 0.45, 0, 1, 1
    // };
    // zig fmt: on
    //_ = positions2;

    const indices = [_]u32{ 0, 1, 2, 2, 3, 0  };

    const layout = Object.Layout.init(&[2]Object.Attrib{ .{ .size = 2 }, .{ .size = 2 } });

    // var rect = Object.init(null, &positions, &indices, layout);
    // defer rect.deinit();
    const rect = try Object.create(&window.renderer, null, &positions, &indices, layout);
    defer rect.deinit();

    const text1 = try Texture.init(app.allocator(), "res/GMOS.png", 1);
    text1.bind();

    const text2 = try Texture.init(app.allocator(), "res/GMOS Back.png", 2);
    text2.bind();

    const text3 = try Texture.init(app.allocator(), "res/Logo.png", 3);
    text3.bind();

    const text4 = try Texture.init(app.allocator(), "res/LogoStraight.png", 4);
    text4.bind();

    rect.setUniform("Color", .{ .color = app.Color.colorRGB(255, 255, 255) });
    rect.setUniform("Texture", .{ .texture = text1 });

    // TODO: FIX TEXTURING SYSTEM
    // currently it only doing 3 instead of 4, see by running app

    while (!window.shouldClose()) {
        if (window.getKeyPress(.one)) {
            rect.setUniform("Texture", .{ .texture = text1 });
        } else if (window.getKeyPress(.two)) {
            rect.setUniform("Texture", .{ .texture = text2 });
        } else if (window.getKeyPress(.three)) {
            rect.setUniform("Texture", . {.texture = text3 });
        } else if (window.getKeyPress(.four)) {
            rect.setUniform("Texture", . {.texture = text4 });
        }

        window.render();
    }
}
