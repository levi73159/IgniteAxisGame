const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const app = @import("app.zig");

const Camera = @import("Display/Camera.zig");
const GameObject = @import("Game/GameObject.zig");
const Shader = @import("Display/Shader.zig");
const Texture = @import("Display/Texture.zig");
const za = @import("zalgebra");

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

    const window = app.createWindow("Main Window", window_width, window_height, null) catch {
        std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    window.background_color = app.Color.white;

    app.setVsync(true);

    const mainCam = Camera.initDefault();
    
    const texture = try Texture.init(app.allocator(), "res/white.png", 0);
    texture.bind();

    const rect = try GameObject.initSquare(&window.renderer, za.Vec2.new(0, 100), za.Vec2.new(100, 100), texture, null);

    // updating the rendering object to be render on the window using the main camera
    var w_btn_press: bool = false;
    var s_btn_press: bool = false;
    while (!window.shouldClose()) {
        if (!w_btn_press and window.getKeyPress(.w)) {
            rect.internal.postion.yMut().* += 1;
            w_btn_press = true;
        } else if (w_btn_press and window.getKeyRelease(.w)) {
            w_btn_press = false;
        }

        if (!s_btn_press and window.getKeyPress(.s)) {
            rect.internal.postion.yMut().* -= 1;
            s_btn_press = true;
        } else if (s_btn_press and window.getKeyRelease(.s)) {
            s_btn_press = false;
        }

        window.update();

        window.render(mainCam);
    }
}
