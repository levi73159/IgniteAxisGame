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
        try Texture.init(allocator, "res/Player.png", 1), // fix unuse
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
        try Game.Scene.fromFile(allocator, "Win", .{ .square = textures[0] })
    });
    defer game.deinit();
    game.mainCam.zoom = 3;
    
    game.setEvents(@import("gameloop.zig"));

    game.start() catch |err| {
        std.log.err("Failed to start game cause: {any}", .{err});
    }; 
}