const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const app = @import("app.zig");
const math = @import("math.zig");

const Game = @import("Game/Game.zig");
const Player = @import("Game/Player.zig");
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
    // Initialize the application
    app.init() catch |err| switch (err) {
        error.AlreadyInit => unreachable,
        error.GLFWInit => {
            std.log.err("Failed to init glfw: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        },
    };
    defer app.deinit();

    const allocator = app.allocator();

    // Create a window
    const window = try app.createWindow("Main Window", window_width, window_height, null);
    window.contex.setAttrib(.resizable, false);
    window.background_color = app.Color.colorF(0.2, 0.4, 0.5);
    app.setVsync(true);

    // Initialize textures
    const textures = [_]Texture{
        try Texture.init(allocator, "res/white.png", 0),
        try Texture.init(allocator, "res/Player.png", 1),
        try Texture.initParameters(allocator, "res/Creates.png", 2, .repeat, .repeat),
        try Texture.initParameters(allocator, "res/Metal.png", 3, .repeat, .repeat),
        try Texture.init(allocator, "res/FlagPole.png", 4),
    };
    defer for (textures) |texture| {
        texture.deinit();
    };

    // Initialize game
    var game = try Game.init(window, Game.Camera.initDefault(za.Vec2.new(window_width, window_height)), &[_]Game.Scene{
        try Game.Scene.fromFile(allocator, "Main", .{ .square = textures[0], .create = textures[2], .metal = textures[3], .pole = textures[4] }),
    });
    defer game.deinit();
    game.mainCam.zoom = 3;

    // Initialize player
    var player =
        try Player.initDefault(&window.renderer, za.Vec2.zero(), gravity, textures[1]);

    game.mainCam.focus(player.game_object.position().*);

    // Get platforms
    const platforms = try game.getObjectTagAlloc(allocator, "Platform");
    defer allocator.free(platforms);

    const win_pole = game.getObject("Win");
    if (win_pole == null) {
        std.log.warn("No Win Pole: can't find object \"Win\"", .{});
    }

    // Game loop
    var timer = try std.time.Timer.start();
    var has_win = false;
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

        if (!has_win) {
            player.update(dt);
            player.collison(platforms, dt);
        }

        if (win_pole) |win_area| {
            if (!has_win and player.isColliding(win_area)) {
                player.game_object.destroy();
                has_win = true;
            }
        }

        // focuos then clamp the bottom of the cam viewport to the ground end
        const bottom_of_ground = platforms[0].internal.postion.y() + platforms[0].internal.scale.y();

        const focus_point = player.game_object.position().add(player.velocity.scale(0.1));
        game.mainCam.focusSmooth(focus_point, (@abs(player.velocity.x()) + 50) * dt);
        game.mainCam.postion.yMut().* = std.math.clamp(game.mainCam.postion.y(), 0, bottom_of_ground - game.mainCam.viewport().y());

        game.render();
    }
}
