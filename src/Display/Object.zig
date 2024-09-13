const std = @import("std");
const gl = @import("gl");
const app = @import("../app.zig");
const za = @import("zalgebra");

const Shader = @import("Shader.zig");
const Camera = @import("Camera.zig");
const Window = @import("Window.zig");

pub const Vertices = @import("Vertices.zig");
pub const Layout = Vertices.Layout;
pub const Attrib = Vertices.Attrib;

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

postion: za.Vec2 = za.Vec2.zero(),
scale: za.Vec2 = za.Vec2.one(),
roation: f32 = 0.0,

vertices: Vertices,
shader: ?Shader, // if null we will have to use drawShader to render obj instead of draw

uniforms: UniformMap,

id: usize,

fn bind(self: Self) void {
    self.vertices.bind();
}

fn unbind() void {
    gl.VertexArray.bind(.invalid);
    gl.Buffer.bind(.invalid, .array_buffer);
    gl.Buffer.bind(.invalid, .element_array_buffer);
}

/// initlize and object and returns said object
pub fn init(shader: ?Shader, vertices: []align(1) const f32, indices: []align(1) const u32, layout: Layout) !Self {
    return Self{
        .vertices = try Vertices.init(vertices, indices, layout),
        .shader = shader,
        .uniforms = UniformMap.init(app.allocator()),
        .id = 0,
    };
}

pub fn initExisting(vertex_id: u32, shader: ?Shader, layout: Layout) ?Self {
    return Self{
        .vertices = Vertices.initExisting(vertex_id, layout) orelse return null, // if can't find, then null
        .shader = shader,
        .uniforms = UniformMap.init(app.allocator()),
        .id = 0, // renderer id, renderer will set that
    };
}

pub fn initFromVertices(vertices: Vertices, shader: ?Shader) Self {
    return Self{
        .vertices = vertices,
        .shader = shader,
        .uniforms = UniformMap.init(app.allocator()),
        .id = 0,
    };
}

/// Creates an object on the heap, adds it to the renderer
pub fn create(renderer: *app.Window.Renderer, shader: ?Shader, vertices: []align(1) const f32, indices: []align(1) const u32, layout: Layout) !*Self {
    const object_ptr = try renderer.allocator.create(Self);

    object_ptr.* = try init(shader, vertices, indices, layout);
    try renderer.addObject(object_ptr);
    return object_ptr;
}

pub fn createExisting(renderer: *app.Window.Renderer, shader: ?Shader, vertex_id: u32, layout: Layout) !*Self {
    const object_ptr = try renderer.allocator.create(Self);
    object_ptr.* = initExisting(vertex_id, shader, layout) orelse initFromVertices(Vertices.initBlank(layout), shader);
    
    try renderer.addObject(object_ptr);
    return object_ptr;
}

/// Clones the object
pub fn clone(self: Self, renderer: *app.Window.Renderer) !*Self {
    const copy_ptr = try renderer.allocator.create(Self);
    copy_ptr.* = self;
    try renderer.addObject(copy_ptr);

    copy_ptr.uniforms = try copy_ptr.uniforms.clone();
    copy_ptr.vertices = copy_ptr.vertices.clone();
    return copy_ptr;
}

pub fn deinit(self: *Self) void {
    self.vertices.deinit();
    self.uniforms.deinit();
}

pub fn setUniform(self: *Self, name: [:0]const u8, value: Shader.UniformType) void {
    self.uniforms.put(name, value) catch |e| {
        std.log.err("Unable to set uniform: {any}", .{e});
    };
}

/// NOTE: DOES NOT CALL `shader.use();` must call before use
fn setShaderUniforms(self: Self, shader: *Shader) void {
    var it = self.uniforms.iterator();
    while (it.next()) |uniform_entry| {
        shader.setUnifrom(uniform_entry.key_ptr.*, uniform_entry.value_ptr.*);
    }
}

pub fn getTransform(self: *const Self) za.Mat4 {
    return za.Mat4.identity()
        .scale(self.scale.toVec3(0))
        .translate(self.postion.toVec3(0))
        .rotate(self.roation, za.Vec3.new(1, 0, 0));
}

/// NOTICE DOES NOT CHANGE ANYTHING Except updating already existing
pub fn draw(self: *Self) void {
    self.bind();

    if (self.shader) |s| {
        s.use();
        self.setShaderUniforms(&(self.shader.?));
    } else {
        std.log.warn("Shader is not define, use drawShader instead!", .{});
    }

    gl.drawElements(.triangles, self.vertices.count, .unsigned_int, 0);
    unbind();
}

pub fn drawShader(self: Self, shader: *Shader) void {
    self.bind();

    shader.use();
    self.setShaderUniforms(shader);

    gl.drawElements(.triangles, self.vertices.count, .unsigned_int, 0);
    unbind();
}
