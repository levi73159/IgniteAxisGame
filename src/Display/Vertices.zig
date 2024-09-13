const std = @import("std");
const gl = @import("gl");

const Self = @This();

pub const Attrib = struct {
    size: u32,
    atype: gl.Type = .float,
    normilized: bool = false,
};
pub const Layout = struct {
    attribs: []const Attrib,
    size: usize,
    vao: gl.VertexArray,

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

const BuffersMap = std.AutoHashMap(u32, struct { uses: u32, indices: u32, count: usize });

/// this is a hash map that will have the vertex_buffer id as a key and the amount of inits as a value
var buffers: ?BuffersMap = null;

vertex_buffer: u32,
indices: u32,
count: usize,
layout: Layout,

pub fn initBuffers(allocator: std.mem.Allocator) void {
    buffers = BuffersMap.init(allocator);
}

pub fn deinitBuffers() void {
    if (buffers != null) {
        buffers.?.deinit();
        buffers = null;
    }
}

pub fn init(vertices: []align(1) const f32, indices: []align(1) const u32, layout: Layout) !Self {
    const vbo = gl.Buffer.gen();
    const ibo = gl.Buffer.gen();

    layout.link(f32, vbo, vertices);

    ibo.bind(gl.BufferTarget.element_array_buffer);
    defer gl.Buffer.bind(.invalid, .element_array_buffer);
    ibo.data(u32, indices, .static_draw);

    if (buffers != null) {
        const result = try buffers.?.getOrPut(@intFromEnum(vbo));
        result.value_ptr.* = .{
            .uses = 1,
            .indices = @intFromEnum(ibo),
            .count = indices.len,
        };
    } else {
        std.log.warn("Buffers Map not init: Vertices.zig", .{});
    }

    return Self{
        .vertex_buffer = @intFromEnum(vbo),
        .indices = @intFromEnum(ibo),
        .count = indices.len,
        .layout = layout,
    };
}

pub fn initExisting(id: u32, layout: Layout) ?Self {
    if (buffers != null) { 
        const maybe_data = buffers.?.getPtr(id);
        if (maybe_data) |data| {
            data.uses += 1;
            return Self{
                .vertex_buffer = id,
                .indices = data.indices,
                .count = data.count,
                .layout = layout,
            };
        }
    }
    std.log.err("Buffer is not initlized", .{});
    return null;
}

/// we can specify a loyout for saftey or else it will just be `undefined`
pub fn initBlank(layout: ?Layout) Self {
    return Self{
        .vertex_buffer = 0,
        .indices = 0,
        .count = 0,
        .layout = layout orelse undefined
    };
}

pub fn bind(self: Self) void {
    self.layout.bind();
    gl.bindBuffer(@enumFromInt(self.indices), .element_array_buffer);
}

pub fn unbind() void {
    gl.VertexArray.bind(.invalid);
    gl.Buffer.bind(.invalid, .array_buffer);
    gl.Buffer.bind(.invalid, .element_array_buffer);
}

pub fn deinit(self: Self) void {
    if (buffers != null) {
        const maybe_uses = buffers.?.getPtr(self.vertex_buffer);
        if (maybe_uses) |data| {
            data.uses -|= 1;
            if (data.uses == 0) {
                gl.deleteBuffer(@enumFromInt(self.vertex_buffer));
                gl.deleteBuffer(@enumFromInt(self.indices));

                _ = buffers.?.remove(self.vertex_buffer);
            }
        }
    }
}

/// this is a dummy function, doesnt actually clone it but it thinks it clones it, aka pretty much clones
pub fn clone(self: Self) Self {
    if (buffers != null) {
        const maybe_uses = buffers.?.getPtr(self.vertex_buffer);
        if (maybe_uses) |uses| {
            uses.* += 1;
        }
    }
    return self;
}
