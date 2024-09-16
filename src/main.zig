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

const window_width = 1000;
const window_height = 600;

const dt_low_limit: f32 = 1.0 / 90.0; // 90 fps
const dt_high_limit: f32 = 1.0 / 10.0; // 10 fps

const gravity: f32 = 723.19;

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
    // var game = try Game.init(window, Game.Camera.initDefault(), &[_]Game.Scene{
    //     Game.Scene.init(allocator, "Playground", &[_]Game.SceneObject{
    //         Game.SceneObject.initSquare("Ground", za.Vec2.new(0, window_height-50), za.Vec2.new(window_width, 50), app.Color.green, square, null),
    //     }),
    // });
    var game = try Game.init(window, Game.Camera.initDefault(), &[_]Game.Scene{
        try Game.Scene.fromFile(allocator, "Main", .{.square = square, .logo = logo}),
    });
    // zig fmt: on
    defer game.deinit();

    const player =
        try GameObject.initSquare(&window.renderer, za.Vec2.new(200, 200), za.Vec2.new(100, 100), app.Color.red, square, null);

    const speed = 500.0;
    const jump_height = 250.0;

    const ground = game.getObject("Ground") orelse unreachable;

    const platforms = try game.getObjectTagAlloc(allocator, "Platform");
    defer allocator.free(platforms);

    var timer = try std.time.Timer.start();
    var velocity = za.Vec2.new(0, 0);
    var is_grounded = false;
    while (!window.shouldClose()) {
        game.update();

        const dt: f32 = blk: {
            var dt: f32 = @as(f32, @floatFromInt(timer.lap())) / std.time.ns_per_s;
            if (dt > dt_high_limit) {
                dt = dt_high_limit;
            } else if (dt < dt_low_limit) {
                dt = dt_low_limit;
            }
            break :blk dt;
        };

        const x = input.getAxis(.a, .d) * speed;

        velocity.xMut().* = x;
        velocity.yMut().* += gravity * dt;

        player.position().* = player.position().add(velocity.mul(za.Vec2.new(dt, dt)));

        {
            is_grounded = false;
            if (player.position().y() + player.scale().y() > ground.position().y()) {
                is_grounded = true;
            }

            // then check collisons
            for (platforms) |platform| {
                if (player.checkCollison(platform)) {
                    // then we need to check if player is above or below
                    if (player.position().y() + player.scale().y() - 5 < platform.position().y()) {
                        player.position().yMut().* = platform.position().y() - player.scale().y();
                        is_grounded = true;
                    } else if (player.position().y() + 10 > platform.position().y() + platform.scale().y()) {
                        player.position().yMut().* = platform.position().y() + platform.scale().y();
                        if (velocity.y() < 0) velocity.yMut().* = 2;
                    } else if (player.position().x() + player.scale().x() - 15 < platform.position().x()) {
                        player.position().xMut().* = platform.position().x() - player.scale().x() - 0.2;
                        velocity.xMut().* = 0;
                    } else if (player.position().x() + 15 > platform.position().x() + platform.scale().x()) {
                        player.position().xMut().* = platform.position().x() + platform.scale().x() + 0.2;
                        velocity.xMut().* = 0;
                    }
                }
            }
        }

        if (is_grounded == true) {
            if (velocity.y() > 0)
                velocity.yMut().* = 2;
            if (input.keyDown(.space)) {
                velocity.yMut().* = -std.math.sqrt(jump_height * 2.0 * gravity);
            }
        }

        player.position().yMut().* = std.math.clamp(player.position().y(), 0, ground.position().y() - player.scale().y());
        player.position().xMut().* = std.math.clamp(player.position().x(), 0, window_width - player.scale().x());

        game.render();
    }
}
