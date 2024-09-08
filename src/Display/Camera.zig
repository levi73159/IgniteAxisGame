const za = @import("zalgebra");

const Self = @This();

postion: za.Vec2,
zoom: f32 = 1,

pub fn init(postion: za.Vec2, zoom: f32) Self {
    return Self{ .postion = postion, .zoom = zoom };
}

pub fn initDefault() Self {
    return Self{ .postion = za.Vec2.zero(), .zoom = 1 };
}

/// return the transoform matrix
pub fn getTransform(self: Self) za.Mat4 {
    return za.Mat4.identity().scale(za.Vec3.new(self.zoom, self.zoom, 0)).translate(self.postion.toVec3(0).negate());
}

pub fn translate(self: *Self, other: za.Vec2) void {
    self.postion.add(other);
}
