/// A Game Object can only be drawn to one window, it should but if it doesn't it may not work probably without changing the renderer
const za = @import("zalgebra");
const app = @import("../app.zig");

const Color = @import("../Display/Color.zig");
const Texture = @import("../Display/Texture.zig");
const Shader = @import("../Display/Shader.zig");
const Object = @import("../Display/Object.zig");
const Window = @import("../Display/Window.zig");

const Self = @This();

// SHADER VARS should be set using functions
// or can be set but then have to call update()
color: Color = Color.white,
texture: Texture,

internal: *Object, // The internal Rendering object
renderer: *Window.Renderer, // reference to the renderer the object is being drawn on

pub fn position(self: *const Self) *za.Vec2 {
    return &self.internal.postion;
}
pub fn scale(self: *const Self) *za.Vec2 {
    return &self.internal.scale;
}

// zig fmt: off
pub fn init(renderer: *Window.Renderer, 
            pos: za.Vec2, _scale: za.Vec2, 
            color: Color, tex: Texture, shader: ?Shader, 
            vertices: []align(1) const f32, 
            indices: []align(1) const u32, 
            layout: Object.Layout) !Self {
    const internal_rendering_object = try Object.create(renderer, shader, vertices, indices, layout);

    return Self.initFromObject(renderer, pos, _scale, color, tex, internal_rendering_object);
}
// zig fmt: on

pub fn initExist(renderer: *Window.Renderer, pos: za.Vec2, _scale: za.Vec2, color: Color, tex: Texture, shader: ?Shader, vertex_id: u32, layout: Object.Layout) !Self {
    const internal_rendering_object = try Object.createExisting(renderer, shader, vertex_id, layout);

    return Self.initFromObject(renderer, pos, _scale, color, tex, internal_rendering_object);
}

/// renderer is what will be rendering the object
pub fn initFromObject(renderer: *Window.Renderer, pos: za.Vec2, _scale: za.Vec2, color: Color, tex: Texture, internal_object: *Object) Self {
    internal_object.setUniform("Color", .{ .color = color });
    internal_object.setUniform("Texture", .{ .texture = tex });

    internal_object.postion = pos;
    internal_object.scale = _scale;
    internal_object.roation = 0;

    return Self{ .texture = tex, .color = color, .internal = internal_object, .renderer = renderer };
}

/// renderer is what will be rendering the object
pub fn initSquare(renderer: *Window.Renderer, pos: za.Vec2, _scale: za.Vec2, color: app.Color, tex: Texture, shader: ?Shader) !Self {
    const positions = [_]f32{
        0, 0, 0, 0, // 0
        1, 0, 1, 0, // 1
        1, 1, 1, 1, // 2
        0, 1, 0, 1, // 3
    };
    const indices = [_]u32{ 0, 1, 2, 2, 3, 0 };
    return Self.init(renderer, pos, _scale, color, tex, shader, &positions, &indices, app.defaultLayout().*);
}

// does not deinit texture, must deinit manually
pub fn deinit(self: *const Self) void {
    self.internal.deinit();
}

pub fn clone(self: Self) !Self {
    return Self{
        .color = self.color,
        .texture = self.texture,
        .renderer = self.renderer,
        .internal = try self.internal.clone(self.renderer),
    };
}

pub fn destroy(self: *Self) void {
    self.renderer.removeIndex(self.internal.id, true);
}

/// **NOTE: SHOULD BE CALL EVERY TIME A VARIABLE IS UPDATED**
pub fn update(self: *Self) void {
    self.internal.setUniform("Color", .{ .color = self.color });
    self.internal.setUniform("Texture", .{ .texture = self.texture });
}

pub fn setColor(self: *Self, color: Color) void {
    self.color = color;
    self.update();
}

pub fn setTexture(self: *Self, texture: Texture) void {
    self.texture = texture;
    self.update();
}

pub fn checkCollison(self: Self, other: Self) bool {
    // check if one object is to the left of the other
    if (self.position().x() + self.scale().x() < other.position().x() or
        other.position().x() + other.scale().x() < self.position().x())
        return false;

    // check if one object is above the other
    if (self.position().y() + self.scale().y() < other.position().y() or
        other.position().y() + other.scale().y() < self.position().y())
        return false;
    
    return true;
}
