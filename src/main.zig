const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const app = @import("app.zig");

const Game = @import("Game/Game.zig");
const GameObject = @import("Game/GameObject.zig");
const Shader = @import("Display/Shader.zig");
const Texture = @import("Display/Texture.zig");
const za = @import("zalgebra");

const Allocator = std.mem.Allocator;

const window_width = 800;
const window_height = 600;

pub fn main() !void {
    app.init() catch |err| switch (err) {
        error.AlreadyInit => unreachable,
        error.GLFWInit => {
            std.log.err("Failed to init glfw: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        },
    };
    defer app.deinit();

    const allocator = app.allocator();

    const window = app.createWindow("Main Window", window_width, window_height, null) catch {
        std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    window.contex.setAttrib(.resizable, false);

    app.setVsync(true);

    const texture = try Texture.init(app.allocator(), "res/white.png", 0);
    defer texture.deinit();
    texture.bind();

    const logo = try Texture.init(app.allocator(), "res/Logo.png", 1);
    defer logo.deinit();
    logo.bind();

    // zig fmt: off
    var game = try Game.init(window, Game.Camera.initDefault(), &[_]Game.Scene{
        Game.Scene.init(allocator, "Main Scene", &[_]Game.SceneObject{
            Game.SceneObject.initSquare(za.Vec2.new(0, 200), za.Vec2.new(100, 100), app.Color.red, texture, null),
            Game.SceneObject.initClone(za.Vec2.new(350, 350), za.Vec2.new(120, 80), app.Color.green, texture, 0)
        }),
        Game.Scene.init(allocator, "Logo", &[_]Game.SceneObject{
            Game.SceneObject.initSquare(za.Vec2.new((window_width/2)-(600/2), window_height), za.Vec2.new(600, 600), app.Color.white, logo, null)
        })
    });
    // zig fmt: on
    defer game.deinit();

    // updating the rendering object to be render on the window using the main camera
    while (!window.shouldClose()) {
        game.update();

        if (window.getKeyPress(.one)) {
            try game.load(0);
            
        } else if (window.getKeyPress(.two)) {
            try game.load(1);
        }

        game.render();
    }
}
