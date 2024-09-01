const std = @import("std");

pub const Vec2 = struct {
    x: f32, y: f32,

    pub fn init(x: f32, y: f32) Vec2 {
        return .{ .x = x, .y = y };
    }

    pub fn distanceSquare(a: Vec2, b: Vec2) f32 {
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        return dx * dx + dy * dy;
    }

    pub fn distance(a: Vec2, b: Vec2) f32 {
        return @sqrt(distanceSquare(a, b));
    }

    pub fn cast2Vec3(vec: Vec2) Vec3 {
        return .{ .x = vec.x, .y = vec.y, .z = 0 };
    }
};

pub const Vec3 = struct {
    x: f32, y: f32, z: f32,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn distanceSquare(a: Vec3, b: Vec3) f32 {
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const dz = b.z - a.z;
        return dx * dx + dy * dy + dz * dz;
    }

    pub fn cast2Vec2(vec: Vec3) Vec2 {
        return .{ .x = vec.x, .y = vec.y };
    }
};
