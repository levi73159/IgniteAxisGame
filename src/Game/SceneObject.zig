const za = @import("zalgebra");
const app = @import("../app.zig");

const GameObject = @import("GameObject.zig");
const Shader = @import("../Display/Shader.zig");
const Object = @import("../Display/Object.zig");
const Texture = @import("../Display/Texture.zig");
const Renderer = @import("../Display/Renderer.zig");

const Self = @This();

const Data = union(enum) {
    raw_data: struct {
        shader: ?Shader,
        vertices: []align(1) const f32,
        indices: []align(1) const u32,
        layout: Object.Layout,
    },
    clone: usize,
    existing: struct { buffer_id: u32, shader: ?Shader, layout: Object.Layout },
};

object: ?GameObject = null,
data: Data,
pos: za.Vec2,
scale: za.Vec2,
texture: Texture,
color: app.Color = app.Color.white,

pub fn init(pos: za.Vec2, scale: za.Vec2, color: app.Color, tex: Texture, shader: ?Shader, vertices: []align(1) const f32, indices: []align(1) const u32, layout: Object.Layout) Self {
    // zig fmt: off
    return Self{
        .pos = pos,
        .scale = scale, 
        .texture = tex, 
        .color = color,
        .data = Data{
            .raw_data  = .{
                .shader = shader,
                .vertices = vertices,
                .indices = indices, 
                .layout = layout
            }
        }
    };
}

pub fn initSquare(pos: za.Vec2, scale: za.Vec2, color: app.Color, tex: Texture, shader: ?Shader) Self {
    const positions = [_]f32{
        0, 0, 0, 1, // 0
        1, 0, 1, 1, // 1
        1, -1, 1, 0, // 2
        0, -1, 0, 0, // 3
    };
    const indices = [_]u32{ 0, 1, 2, 2, 3, 0 };
    
    return init(pos, scale, color, tex, shader, &positions, &indices, app.defaultLayout().*);
}

pub fn initClone(pos: za.Vec2, scale: za.Vec2, color: app.Color, tex: Texture, index: usize) Self {
    return Self{ 
        .pos = pos,
        .scale = scale,
        .color = color,
        .texture = tex,
        .data = Data{ .clone = index } 
    };
}

pub fn initExisting(pos: za.Vec2, scale: za.Vec2, color: app.Color, tex: Texture, buffer_id: u32, shader: ?Shader, layout: Object.Layout) Self {
    return Self{
        .pos = pos,
        .scale = scale,
        .color = color,
        .texture = tex,
        .data = Data{
            .existing = .{
                .buffer_id = buffer_id,
                .shader = shader,
                .layout = layout,
            }
        }
    };
}
// zig fmt: on

pub fn load(self: *Self, renderer: *Renderer, objects: []const Self) !void {
    // zig fmt: off
        if (self.data == .raw_data) {
            self.object = try GameObject.init(
                renderer, 
                self.pos, 
                self.scale,
                self.color,
                self.texture, 
                self.data.raw_data.shader, 
                self.data.raw_data.vertices,
                self.data.raw_data.indices,
                self.data.raw_data.layout
            );
        } else if (self.data == .clone) {
            const obj_to_clone = objects[self.data.clone];
            if (obj_to_clone.object) |go| {
                self.object = try GameObject.initExist(renderer, 
                    self.pos, 
                    self.scale, 
                    self.color,
                    self.texture, 
                    go.internal.shader, 
                    go.internal.vertices.vertex_buffer, 
                    go.internal.vertices.layout
                );
            }
        } else if (self.data == .existing) {
            self.object = try GameObject.initExist(
                renderer,
                self.pos, 
                self.scale, 
                self.color,
                self.texture,
                self.data.existing.shader,
                self.data.existing.buffer_id,
                self.data.existing.layout
            );
        }
        // zig fmt: on
}

// just deinitlizes the game object
pub fn deinit(self: *Self) void {
    if (self.object != null) {
        self.object.?.destroy();
        self.object = null;
    }
}
