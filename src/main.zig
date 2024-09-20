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

const dt_low_limit: f32 = 1.0 / 60.0; // 90 fps
const dt_high_limit: f32 = 1.0 / 10.0; // 10 fps

const gravity: f32 = 241.19;

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

    const player_tex = try Texture.init(app.allocator(), "res/Player.png", 1);
    defer player_tex.deinit();
    player_tex.bind();

    const create = try Texture.initParameters(app.allocator(), "res/Creates.png", 2, .repeat, .repeat);
    defer create.deinit();
    create.bind();

    const metal = try Texture.initParameters(app.allocator(), "res/Metal.png", 3, .repeat, .repeat);
    defer metal.deinit();
    metal.bind();

    var game = try Game.init(window, Game.Camera.initDefault(), &[_]Game.Scene{
        try Game.Scene.fromFile(allocator, "Main", .{ .square = square, .create = create, .metal = metal }),
    });
    defer game.deinit();
    game.mainCam.zoom = 3;

    const player =
        try GameObject.initSquare(&window.renderer, za.Vec2.new(200, 200), za.Vec2.new(25, 25), app.Color.white, player_tex, null);

    // variable setup
    const speed = 163.0;
    const jump_height = 83.0;

    const ground = game.getObject("Ground") orelse unreachable;
    var is_grounded = false;

    const platforms = try game.getObjectTagAlloc(allocator, "Platform");
    defer allocator.free(platforms);

    var timer = try std.time.Timer.start();
    var velocity = za.Vec2.new(0, 0);

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

        velocity.xMut().* = x * dt;
        velocity.yMut().* += gravity * dt * dt;

        player.position().* = player.position().add(velocity);

        {
            is_grounded = false;
            if (player.position().y() + player.scale().y() > ground.position().y()) {
                is_grounded = true;
            }

            // then check collisons
            for (platforms) |platform| {
                if (player.checkCollison(platform)) {
                    // then we need to check if player is above or below
                    const offsetX: f32 = @abs(velocity.x()) * 2;
                    const offsetY: f32 = @abs(velocity.y()) * 2;
                    if (player.position().y() + player.scale().y() - offsetY < platform.position().y()) {
                        player.position().yMut().* = platform.position().y() - player.scale().y();
                        is_grounded = true;
                    } else if (player.position().y() + offsetY > platform.position().y() + platform.scale().y()) {
                        player.position().yMut().* = platform.position().y() + platform.scale().y();
                        if (velocity.y() < 0) velocity.yMut().* = 1 * dt;
                    } else if (player.position().x() + player.scale().x() - offsetX < platform.position().x()) {
                        player.position().xMut().* = platform.position().x() - player.scale().x() - 0.2;
                        velocity.xMut().* = 0;
                    } else if (player.position().x() + offsetX > platform.position().x() + platform.scale().x()) {
                        player.position().xMut().* = platform.position().x() + platform.scale().x() + 0.2;
                        velocity.xMut().* = 0;
                    }
                }
            }
        }

        if (is_grounded == true) {
            if (velocity.y() > 0)
                velocity.yMut().* = 1 * dt;
            if (input.keyDown(.space)) {
                velocity.yMut().* = -std.math.sqrt(jump_height * 2.0 * gravity) * dt;
            }
        }

        player.position().yMut().* = std.math.clamp(player.position().y(), -1000, ground.position().y() - player.scale().y());
        player.position().xMut().* = std.math.clamp(player.position().x(), 0, window_width - player.scale().x());

        game.render();
    }
}
