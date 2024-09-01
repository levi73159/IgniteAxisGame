const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
const app = @import("Display/app.zig");

const Object = @import("Object.zig");
const Shader = @import("Shader.zig");

const Allocator = std.mem.Allocator;


const window_width = 800;
const window_height = 600;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const denit_status = gpa.deinit();
        if (denit_status == .leak) std.debug.print("Mem leak detected", .{});
    }
    const allocator = gpa.allocator();

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



    const window = app.createWindow("Main Window", .{.x = window_width, .y = window_height}) catch {
        std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };

    // zig fmt: off
    const positions = [_]f32{
        -0.5, -0.5,     // 0
        0.5, -0.5,      // 1
        0.5, 0.5,       // 2
        -0.5, 0.5,      // 3
    };
    // zig fmt: on

    const indices = [_]u32 { 0, 1, 2, 2, 3, 0 };


    const shader = Shader.init(allocator, "res/vertex.glsl", "res/fragment.glsl");
    defer shader.deinit();

    const layout = Object.Layout.init(&[1]Object.Attrib { .{ .size = 2 } });

    const rect = Object.init(&shader, &positions, &indices, layout);
    defer rect.deinit();

    // const shader = Shader.init(allocator, "res/vertex.glsl", "res/fragment.glsl");

    while (!window.shouldClose()) {
        app.clear();

        rect.draw();
        window.window_ctx.swapBuffers();

        glfw.pollEvents();
    }
}
