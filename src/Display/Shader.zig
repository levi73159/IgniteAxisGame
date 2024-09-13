const std = @import("std");
const gl = @import("gl");

const Allocator = std.mem.Allocator;
const Color = @import("Color.zig");
const Texture = @import("Texture.zig");
const Self = @This();
const math = @import("zalgebra");

var current_shader: u32 = 0; // 0 is invalid, see gl.Shader

shader_id: u32,
uniform_cache: std.StringHashMap(u32),

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

fn createShader(allocator: Allocator, shadername: []const u8) u32 {
    const vertex_filepath = std.fmt.allocPrint(allocator, "res/{s}.vert", .{shadername}) catch |err| {
        std.log.err("{any}", .{err});
        return 0;
    };
    defer allocator.free(vertex_filepath);

    const frag_filepath = std.fmt.allocPrint(allocator, "res/{s}.frag", .{shadername}) catch |err| {
        std.log.err("{any}", .{err});
        return 0;
    };
    defer allocator.free(frag_filepath);

    // read the two files
    const program = gl.Program.create();
    const vertex_shader: gl.Shader = compileShader(allocator, .vertex, vertex_filepath) catch |err| blk: {
        std.log.err("Failed to compile fragment shader: {any}", .{err});
        break :blk .invalid;
    };
    defer vertex_shader.delete();

    const frag_shader: gl.Shader = compileShader(allocator, .fragment, frag_filepath) catch |err| blk: {
        std.log.err("Failed to compile fragment shader: {any}", .{err});
        break :blk .invalid;
    };
    defer frag_shader.delete();

    program.attach(vertex_shader);
    program.attach(frag_shader);
    program.link();

    return @intFromEnum(program);
}

pub fn init(allocator: Allocator, shadername: []const u8) Self {
    const shader_id = createShader(allocator, shadername);
    return Self{ .shader_id = shader_id, .uniform_cache = std.StringHashMap(u32).init(allocator) };
}

pub fn use(self: Self) void {
    if (current_shader == self.shader_id) return;

    gl.useProgram(@enumFromInt(self.shader_id));
    current_shader = self.shader_id;
}

pub fn deinit(self: *Self) void {
    gl.deleteProgram(@enumFromInt(self.shader_id));
    self.uniform_cache.deinit();
}

fn getUniform(self: *Self, name: [:0]const u8) ?u32 {
    self.use();

    const real_name = blk: {
        var buffer: [255]u8 = undefined;
        const s: [:0]const u8 = std.fmt.bufPrintZ(&buffer, "u_{s}", .{name}) catch |err| {
            std.log.err("Failed to get unifrom real name because of BufPrintError: {any}", .{err});
            return null;
        };
        break :blk s;
    };

    const location: ?u32 = blk: {
        const maybe_location = self.uniform_cache.get(name);
        if (maybe_location) |loc| {
            break :blk loc;
        } else {
            const maybe_loc = gl.getUniformLocation(@enumFromInt(self.shader_id), real_name);
            if (maybe_loc) |loc| {
                self.uniform_cache.put(name, loc) catch {
                    std.log.err("OUT OF MEMORY IN UNIFROM CACHE!", .{});
                };
            }
            break :blk maybe_loc; // don't care if null or not
        }
    };
    if (location == null) {
        std.log.warn("Can't find unfiorm {s}", .{name});
    }
    return location;
}

pub const UniformType = union(enum) { int: i32, color: Color, vec2: math.Vec2, vec3: math.Vec3, vec4: math.Vec4, mat4: math.Mat4, texture: Texture };

pub fn setUnifrom(self: *Self, name: [:0]const u8, unifrom: UniformType) void {
    switch (unifrom) {
        .color => self.setUniformColor(name, unifrom.color),
        .vec2 => self.setUniformVec2(name, unifrom.vec2),
        .vec3 => self.setUniformVec3(name, unifrom.vec3),
        .vec4 => self.setUnifromVec4(name, unifrom.vec4),
        .int => self.setUnifromInt(name, unifrom.int),
        .texture => self.setUnifromInt(name, @intCast(unifrom.texture.slot)),
        .mat4 => self.setUniformMat4(name, unifrom.mat4),
    }
}

pub fn setUniformColor(self: *Self, name: [:0]const u8, color: Color) void {
    const uniform = self.getUniform(name) orelse return;

    const real_color = color.getRealColor();
    gl.uniform4f(uniform, real_color.r, real_color.g, real_color.b, real_color.a);
}

pub fn setUnifromVec4(self: *Self, name: [:0]const u8, vec: math.Vec4) void {
    const uniform = self.getUniform(name) orelse return;
    gl.uniform4f(uniform, vec.x(), vec.y(), vec.z(), vec.w());
}

pub fn setUniformVec3(self: *Self, name: [:0]const u8, vec: math.Vec3) void {
    const uniform = self.getUniform(name) orelse return;
    gl.uniform3f(uniform, vec.x(), vec.y(), vec.z());
}

pub fn setUniformVec2(self: *Self, name: [:0]const u8, vec: math.Vec2) void {
    const uniform = self.getUniform(name) orelse return;
    gl.uniform2f(uniform, vec.x(), vec.y());
}

pub fn setUnifromInt(self: *Self, name: [:0]const u8, int: i32) void {
    const unifrom = self.getUniform(name) orelse return;
    gl.uniform1i(unifrom, int);
}

pub fn setUniformMat4(self: *Self, name: [:0]const u8, matrix: math.Mat4) void {
    const unifrom = self.getUniform(name) orelse return;
    gl.uniformMatrix4fv(
        unifrom,
        true,
        &[_][4][4]f32{matrix.data},
    );
}
