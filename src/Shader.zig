const std = @import("std");
const gl = @import("gl");

const Allocator = std.mem.Allocator;
const Self = @This();

program: gl.Program,

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

pub fn init(allocator: Allocator, vertex_filename: []const u8, frag_filename: []const u8) Self {
    const shader_program = createShader(allocator, vertex_filename, frag_filename);
    return .{ .program = shader_program };
}

pub fn use(self: Self) void {
    self.program.use();
}

pub fn deinit(self: Self) void {
    self.program.delete();
}