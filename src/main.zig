const std = @import("std");
const ia = @import("ignite-axis");

const input = ia.input;

const Allocator = std.mem.Allocator;

const dbg = @import("builtin").mode == .Debug;
const window_width = 1000;
const window_height = 600;

pub fn main() !void {
    // Initialize the application
    ia.init() catch |err| switch (err) {
        error.AlreadyInit => unreachable,
        error.GLFWInit => {
            std.log.err("Failed to init glfw app: {?s}", .{ia.glfwErrorString()});
            std.process.exit(1);
        },
    };
    defer ia.deinit();

    const allocator = ia.allocator();

    // now we want to get args
    const start_scene: usize = blk: {
        if (!dbg) break :blk 0;
        const args = try std.process.argsAlloc(allocator);
        defer std.process.argsFree(allocator, args);

        if (args.len > 1) {
            std.debug.print("scene to start: {s}\n", .{args[1]});
            break :blk try std.fmt.parseUnsigned(usize, args[1], 10);
        }

        break :blk 0;
    };

    // Create a window
    const window = try ia.createWindow("Main Window", window_width, window_height, null);
    window.contex.setAttrib(.resizable, false);
    window.background_color = ia.Color.colorF(0.2, 0.4, 0.5);
    ia.setVsync(true);

    // Initialize game
    // zig fmt: off
    var game = try ia.Game.init(window, ia.Game.Camera.initDefault(ia.math.Vec2.new(window_width, window_height)), &[_]ia.Game.Scene{ 
        try ia.Game.Scene.fromFile(allocator, "Main", .{})
    });
    defer game.deinit();

    // zig fmt: on
    game.mainCam.zoom = 3;
    game.current_scene_index = start_scene; // gonna start at start_scene

    game.setEvents(@import("gameloop.zig"));

    game.start() catch |err| {
        std.log.err("Failed to start game cause: {any}", .{err});
    };
}
