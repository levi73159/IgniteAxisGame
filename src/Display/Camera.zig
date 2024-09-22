const za = @import("zalgebra");
const math = @import("../math.zig");

const Self = @This();

postion: za.Vec2,
zoom: f32,

/// should never be motify, only by the window when it resizes
///
/// this holds the window viewport in it, if you want to get the camera viewport use `cam.viewport()`
_viewport: za.Vec2,

pub fn init(postion: za.Vec2, zoom: f32, window_viewport: za.Vec2) Self {
    return Self{ .postion = postion, .zoom = zoom, ._viewport = window_viewport };
}

pub fn initDefault(window_viewport: za.Vec2) Self {
    return Self{ .postion = za.Vec2.zero(), .zoom = 1, ._viewport = window_viewport };
}

pub fn viewport(self: Self) za.Vec2 {
    return self._viewport.mul(za.Vec2.new(1 / self.zoom, 1 / self.zoom));
}

/// return the transoform matrix
pub fn getTransform(self: Self) za.Mat4 {
    return za.Mat4.identity().translate(self.postion.toVec3(0).negate()).scale(za.Vec3.new(self.zoom, self.zoom, 0));
}

pub fn translate(self: *Self, other: za.Vec2) void {
    self.postion = self.postion.add(other);
}

pub fn focus(self: *Self, point: za.Vec2) void {
    const cam_vp = self.viewport();
    self.postion = point; // set the point to be top left now move the point in the center of screen
    self.translate(cam_vp.scale(-0.5));
}

pub fn focusSmooth(self: *Self, point: za.Vec2, step: f32) void {
    const cam_vp = self.viewport();
    const p = point.add(cam_vp.scale(-0.5)); // set the point to be top left now move the point in the center of screen

    const x = math.moveToward(self.postion.x(), p.x(), step);
    const y = math.moveToward(self.postion.y(), p.y(), step);
    self.postion = za.Vec2.new(x, y);
}
