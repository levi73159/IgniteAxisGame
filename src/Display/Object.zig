const std = @import("std");
const gl = @import("gl");
const Shader = @import("Shader.zig");
const app = @import("../app.zig");

pub const Attrib = struct {
    size: u32,
    atype: gl.Type = .float,
    normilized: bool = false,
};
pub const Layout = struct {
    attribs: []const Attrib,
    size: usize,
    vao: gl.VertexArray,

    pub fn init(attribs: []const Attrib) Layout {
        var size: usize = 0;
        for (attribs) |attrib| {
            const type_size = getSize(attrib.atype);
            size += attrib.size * type_size;
        }
        return .{ .attribs = attribs, .size = size, .vao = gl.VertexArray.gen() };
    }

    /// links the `array_buffer` to the layout
    pub fn link(layout: Layout, comptime T: type, array_buffer: gl.Buffer, vertices: []align(1) const T) void {
        var data_size: usize = 0;
        layout.vao.bind();
        defer gl.VertexArray.bind(.invalid);

        array_buffer.bind(.array_buffer);
        defer gl.Buffer.bind(.invalid, .array_buffer);
        array_buffer.data(T, vertices, .static_draw);

        for (layout.attribs, 0..) |attrib, index| {
            gl.vertexAttribPointer(@intCast(index), attrib.size, attrib.atype, attrib.normilized, layout.size, data_size);
            gl.enableVertexAttribArray(@intCast(index));
            // std.debug.print("Attrib {}: size={}, type={}, normilized={}, stride={}, offset={}\n", .{index, attrib.size, attrib.atype, attrib.normilized, layout.size, data_size});
            data_size += attrib.size * getSize(attrib.atype);
        }
    }

    pub fn set(layout: Layout, array_buffer: gl.Buffer) void {
        layout.vao.bind();
        defer gl.VertexArray.bind(.invalid);

        array_buffer.bind(.array_buffer);
        defer gl.Buffer.bind(.invalid, .array_buffer);

        var data_size: usize = 0;
        for (layout.attribs, 0..) |attrib, index| {
            gl.vertexAttribPointer(@intCast(index), attrib.size, attrib.atype, attrib.normilized, layout.size, data_size);
            gl.enableVertexAttribArray(@intCast(index));
            // std.debug.print("Attrib {}: size={}, type={}, normilized={}, stride={}, offset={}\n", .{index, attrib.size, attrib.atype, attrib.normilized, layout.size, data_size});
            data_size += attrib.size * getSize(attrib.atype);
        }
    }

    pub fn delete(layout: Layout) void {
        layout.vao.delete();
    }

    pub fn bind(layout: Layout) void {
        layout.vao.bind();
    }

    pub fn unbind() void {
        gl.VertexArray.bind(.invalid);
    }
};

const Allocator = std.mem.Allocator;
const Self = @This();

const UnifromMapContext = struct {
    pub fn hash(self: @This(), s: [:0]const u8) u32 {
        _ = self;
        return std.hash.CityHash32.hash(s);
    }
    pub fn eql(self: @This(), a: [:0]const u8, b: [:0]const u8, b_index: usize) bool {
        _ = self;
        _ = b_index;
        return std.mem.eql(u8, a, b);
    }
};

const UniformMap = std.ArrayHashMap([:0]const u8, Shader.UniformType, UnifromMapContext, true);

vbo: gl.Buffer,
ibo: gl.Buffer,
vert_count: usize,
layout: Layout,
shader: ?Shader, // if null we will have to use drawShader to render obj instead of draw

uniforms: UniformMap,

fn bindAll(self: Self) void {
    self.layout.bind();
    self.ibo.bind(gl.BufferTarget.element_array_buffer);
}

fn unbind() void {
    gl.VertexArray.bind(.invalid);
    gl.Buffer.bind(.invalid, .array_buffer);
    gl.Buffer.bind(.invalid, .element_array_buffer);
}

fn getSize(t: gl.Type) usize {
    return switch (t) {
        .byte, .unsigned_byte => @sizeOf(gl.Byte),
        .short, .unsigned_short => @sizeOf(gl.Short),
        .int, .unsigned_int => @sizeOf(gl.Int),
        .float => @sizeOf(gl.Float),
        else => blk: {
            std.log.warn("Invalid Type: {}", .{t});
            break :blk 0;
        },
    };
}

pub fn init(shader: ?Shader, vertices: []align(1) const f32, indices: []align(1) const u32, layout: Layout) Self {
    const vbo = gl.Buffer.gen();
    const ibo = gl.Buffer.gen();

    layout.link(f32, vbo, vertices);

    ibo.bind(gl.BufferTarget.element_array_buffer);
    defer gl.Buffer.bind(.invalid, .element_array_buffer);
    ibo.data(u32, indices, .static_draw);
    // defer gl.Buffer.bind(.invalid, .element_array_buffer); // unbinding

    return Self{
        .vbo = vbo,
        .ibo = ibo,
        .vert_count = indices.len,
        .shader = shader,
        .layout = layout,
        .uniforms = UniformMap.init(app.allocator()),
    };
}

pub fn deinit(self: *Self) void {
    self.vbo.delete();
    self.ibo.delete();
    self.layout.delete();
    self.uniforms.deinit();
}

pub fn setUniform(self: *Self, name: [:0]const u8, value: Shader.UniformType) void {
    self.uniforms.put(name, value) catch |e| {
        std.log.err("Unable to set uniform: {any}", .{e});
    };
}

/// NOTE: DOES NOT CALL `shader.use();` must call before use
fn setShaderUniforms(self: Self, shader: *const Shader) void {
    var it = self.uniforms.iterator();
    while (it.next()) |uniform_entry| {
        switch (uniform_entry.value_ptr.*) {
            .color => shader.setUniformColor(uniform_entry.key_ptr.*, uniform_entry.value_ptr.color),
            .vec2 => shader.setUniformVec2(uniform_entry.key_ptr.*, uniform_entry.value_ptr.vec2),
            .vec3 => shader.setUniformVec3(uniform_entry.key_ptr.*, uniform_entry.value_ptr.vec3),
            .vec4 => shader.setUnifromVec4(uniform_entry.key_ptr.*, uniform_entry.value_ptr.vec4),
        }
    }
}

pub fn draw(self: Self) void {
    self.layout.set(self.vbo);
    self.bindAll();

    if (self.shader) |s| {
        s.use();
        self.setShaderUniforms(&s);
    } else {
        std.log.warn("Shader is not define, use drawShader instead!", .{});
    }

    gl.drawElements(.triangles, self.vert_count, .unsigned_int, 0);
    unbind();
}

pub fn drawShader(self: Self, shader: *const Shader) void {
    self.layout.set(self.vbo);
    self.bindAll();

    shader.use();
    self.setShaderUniforms(shader);

    gl.drawElements(.triangles, self.vert_count, .unsigned_int, 0);
    unbind();
}
