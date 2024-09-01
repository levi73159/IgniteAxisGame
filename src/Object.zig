const std = @import("std");
const gl = @import("gl");
const Shader = @import("Shader.zig");

pub const Attrib = struct {
    size: u32,
    atype: gl.Type = .float,
    normilized: bool = false,
};
pub const Layout = struct {
    attribs: []const Attrib,
    size: usize,

    pub fn init(attribs: []const Attrib) Layout {
        var size: usize = 0;
        for (attribs) |attrib| {
            const type_size = getSize(attrib.atype);
            size += attrib.size * type_size;
        }
        return .{ .attribs = attribs, .size = size };
    }

    pub fn set(layout: Layout) void {
        var data_size: usize = 0;
        for (layout.attribs, 0..) |attrib, index| {
            gl.vertexAttribPointer(@intCast(index), attrib.size, attrib.atype, attrib.normilized, layout.size, data_size);
            gl.enableVertexAttribArray(@intCast(index));
            std.debug.print("Attrib {}: size={}, type={}, normilized={}, stride={}, offset={}\n", .{index, attrib.size, attrib.atype, attrib.normilized, layout.size, data_size});
            data_size += attrib.size * getSize(attrib.atype);
        }
    }
};

const Allocator = std.mem.Allocator;
const Self = @This();

vao: gl.VertexArray,
vbo: gl.Buffer,
ibo: gl.Buffer,
vert_count: usize,
shader: ?*const Shader, // if null we will have to use drawShader to render obj instead of draw

fn bindAll(self: Self) void {
    self.vao.bind();
    self.vbo.bind(gl.BufferTarget.array_buffer);
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

pub fn init(shader: ?*const Shader, vertices: []align(1) const f32, indices: []align(1) const u32, layout: ?Layout) Self {
    const vao = gl.VertexArray.gen();
    const vbo = gl.Buffer.gen();
    const ibo = gl.Buffer.gen();

    vao.bind();
    defer gl.VertexArray.bind(.invalid);

    vbo.bind(.array_buffer);
    defer gl.Buffer.bind(.invalid, .array_buffer);

    vbo.data(f32, vertices, .static_draw);
    if (layout) |l| l.set();

    ibo.bind(gl.BufferTarget.element_array_buffer);
    ibo.data(u32, indices, .static_draw);
    // defer gl.Buffer.bind(.invalid, .element_array_buffer); // unbinding

    return .{ .vao = vao, .vbo = vbo, .ibo = ibo, .vert_count = indices.len, .shader = shader };
}

pub fn deinit(self: Self) void {
    self.vao.delete();
    self.vbo.delete();
    self.ibo.delete();
}

pub fn setLayout(self: Self, layout: Layout) void {
    self.vao.bind();
    self.vbo.bind(.array_buffer);
    defer unbind();

    layout.set();    
}

pub fn draw(self: Self) void {
    self.bindAll();
    
    if (self.shader) |s| {
        s.use();
    } else {
        std.log.warn("Shader is not define, use drawShader instead!", .{});
    }

    gl.drawElements(.triangles, self.vert_count, .unsigned_int, 0);
    unbind();
}

pub fn drawShader(self: Self, shader: *const Shader) void {
    self.bindAll();
    
    shader.use();

    gl.drawElements(.triangles, self.vert_count, .unsigned_int, 0);
    unbind();
}
