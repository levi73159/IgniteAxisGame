const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

const log = std.log.scoped(.triangle);

fn glGetProcAddress(_: glfw.GLProc, proc: [:0]const u8) ?gl.binding.FunctionPointer {
    return glfw.getProcAddress(proc);
}

const window_width = 800;
const window_height = 600;

pub fn main() !void {
    if (!glfw.init(.{})) {
        log.err("Failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    var window: glfw.Window = glfw.Window.create(window_width, window_height, "Hello, World", null, null, .{}) orelse {
        log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    // /* Make the window's context current */
    // glfwMakeContextCurrent(window);
    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.loadExtensions(proc, glGetProcAddress);

    // /* Loop until the user closes the window */
    // while (!glfwWindowShouldClose(window))
    // {
    //     /* Render here */
    //     glClear(GL_COLOR_BUFFER_BIT);

    //     /* Swap front and back buffers */
    //     glfwSwapBuffers(window);

    //     /* Poll for and process events */
    //     glfwPollEvents();
    // }

    var inc_r: f32 = 0.01;
    var inc_g: f32 = 0.05;
    var inc_b: f32 = 0.02;
    var r: f32 = 0;
    var g: f32 = 0;
    var b: f32 = 0;

    while (!window.shouldClose()) {
        gl.clearColor(r, g, b, 1);
        gl.clear(.{ .color = true });

        window.swapBuffers();

        r += inc_r;
        g += inc_g;
        b += inc_b;

        if (r > 1 or r < 0) inc_r = -inc_r;
        if (g > 1 or g < 0) inc_g = -inc_g;
        if (b > 1 or b < 0) inc_b = -inc_b;

        glfw.pollEvents();
    }
}
