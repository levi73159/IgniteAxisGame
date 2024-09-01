const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");

const Allocator = std.mem.Allocator;

fn glGetProcAddress(_: glfw.GLProc, proc: [:0]const u8) ?gl.binding.FunctionPointer {
    return glfw.getProcAddress(proc);
}

fn compileShader(allocator: Allocator, shaderType: gl.ShaderType, filename: []const u8) !gl.Shader {
    const shader = gl.Shader.create(shaderType);
    errdefer shader.delete();

    const file = try std.fs.cwd().openFile(filename, .{});

    const source = try file.readToEndAlloc(allocator, 2048 * 2048);
    defer allocator.free(source);

    shader.source(1, &[_][]const u8{source});
    shader.compile();

    const result = shader.get(.compile_status);
    if (result == 0) {
        // gl.getShaderInfoLog(shader: types.Shader, allocator: std.mem.Allocator)
        const log = shader.getCompileLog(allocator) catch |err| {
            std.log.err("Unable to get shader compile log on fail!, reason: {any}", .{err});
            return error.shaderCompile;
        };
        std.log.err("Failed to compile {s} shader!", .{@tagName(shaderType)});
        std.debug.print("{s}", .{log});
        return error.shaderCompile;
    }

    return shader;
}

fn createShader(allocator: Allocator, vert_shader_filename: []const u8, frag_shader_filename: []const u8) gl.Program {
    // read the two files
    const program = gl.Program.create();
    const vertex_shader: gl.Shader = compileShader(allocator, .vertex, vert_shader_filename) catch |err| blk: {
        std.log.err("Failed to compile fragment shader: {any}", .{err});
        break :blk @enumFromInt(0);
    };
    defer vertex_shader.delete();

    const frag_shader: gl.Shader = compileShader(allocator, .fragment, frag_shader_filename) catch |err| blk: {
        std.log.err("Failed to compile fragment shader: {any}", .{err});
        break :blk @enumFromInt(0);
    };
    defer frag_shader.delete();

    program.attach(vertex_shader);
    program.attach(frag_shader);
    program.link();

    return program;
}

const window_width = 800;
const window_height = 600;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const denit_status = gpa.deinit();
        if (denit_status == .leak) std.debug.print("Mem leak detected", .{});
    }
    const allocator = gpa.allocator();

    if (!glfw.init(.{})) {
        std.log.err("Failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    var window: glfw.Window = glfw.Window.create(window_width, window_height, "Hello, World", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 3,
        .context_version_minor = 3,
    }) orelse {
        std.log.err("Failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    // /* Make the window's context current */
    // glfwMakeContextCurrent(window);
    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.loadExtensions(proc, glGetProcAddress);

    std.debug.print("Version: {s}\n", .{gl.getString(.version) orelse "null"});
    gl.viewport(0, 0, window_width, window_height);

    // zig fmt: off
    const positions = [_]f32{
        -0.5, -0.5,     // 0
        0.5, -0.5,      // 1
        0.5, 0.5,       // 2
        -0.5, 0.5,      // 3
    };
    // zig fmt: on

    const indices = [_]u32 { 0, 1, 2, 2, 3, 0 };

    const vao = gl.VertexArray.gen();
    const vbo = gl.Buffer.gen();
    const ibo = gl.Buffer.gen();

    defer vao.delete();
    defer vbo.delete();
    defer ibo.delete();
    
    vao.bind();
    vbo.bind(.array_buffer);

    vbo.data(f32, &positions, .static_draw);
    gl.vertexAttribPointer(0, 2, gl.Type.float, false, 2 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(0);

    ibo.bind(gl.BufferTarget.element_array_buffer);
    ibo.data(u32, &indices, .static_draw);

    const shader = createShader(allocator, "res/vertex.glsl", "res/fragment.glsl");
    defer shader.delete();

    shader.use();

    vao.bind();
    while (!window.shouldClose()) {
        gl.clearColor(0, 0, 0, 1);
        gl.clear(.{ .color = true });

        shader.use();
        gl.drawElements(.triangles, 6, .unsigned_int, 0);

        window.swapBuffers();

        glfw.pollEvents();
    }
}
