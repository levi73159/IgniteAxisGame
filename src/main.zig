const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const app = @import("app.zig");

const Game = @import("Game/Game.zig");
const GameObject = @import("Game/GameObject.zig");
const Shader = @import("Display/Shader.zig");
const Texture = @import("Display/Texture.zig");
const za = @import("zalgebra");

const input = app.input;

const Allocator = std.mem.Allocator;

const window_width = 800;
const window_height = 600;

const dt_low_limit: f32 = 1000 / 60; // 60 fps
const dt_high_limit: f32 = 1000 / 10; // 10 fps

pub fn main() !void {
    // init app
    app.init() catch |err| switch (err) {
        error.AlreadyInit => unreachable,
        error.GLFWInit => {
            std.log.err("Failed to init glfw: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        },
    };
    defer app.deinit();

    const allocator = app.allocator();

    // creating a window
    const window = app.createWindow("Main Window", window_width, window_height, null) catch {
        std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    window.contex.setAttrib(.resizable, false);
    window.background_color = app.Color.colorF(0.2, 0.4, 0.5);

    app.setVsync(true);

    // initlize textures
    const square = try Texture.init(app.allocator(), "res/white.png", 0);
    defer square.deinit();
    square.bind();

    const logo = try Texture.init(app.allocator(), "res/Logo.png", 1);
    defer logo.deinit();
    logo.bind();

    // initlizeing game and it scenes
    // zig fmt: off
    var game = try Game.init(window, Game.Camera.initDefault(), &[_]Game.Scene{
        Game.Scene.init(allocator, "Playground", &[_]Game.SceneObject{
            Game.SceneObject.initSquare(za.Vec2.new(0, window_height-50), za.Vec2.new(window_width, 50), app.Color.green, square, null),
        }),
    });
    // zig fmt: on
    defer game.deinit();

    var player =
        try GameObject.initSquare(&window.renderer, za.Vec2.new(200, 200), za.Vec2.new(100, 100), app.Color.red, square, null);
    const speed = 5.0;

    const timer = try std.time.Timer.start();
    while (!window.shouldClose()) {
        game.update();

        const dt: f32 = @truncate(@as(f64, @floatFromInt(timer.lap())) / 1e-9);

        const x = input.getAxis(.a, .d);
        const y = input.getAxis(.w, .s);
        const velocity = za.Vec2.new(x * speed * dt, y * speed * dt);
        player.internal.postion = player.internal.postion.add(velocity);

        game.render();
    }
}
