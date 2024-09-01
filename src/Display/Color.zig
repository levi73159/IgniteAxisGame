const Self = @This();

r: u8,
g: u8,
b: u8,
a: u8 = 255,

pub const black = colorRGB(0, 0, 0);
pub const white = colorRGB(255, 255, 255);
pub const red = colorRGB(255, 0, 0);
pub const green = colorRGB(0, 255, 0);
pub const blue = colorRGB(0, 0, 255);

const RealColor = struct { r: f32, g: f32, b: f32, a: f32 };

pub fn colorRGB(r: u8, g: u8, b: u8) Self {
    return .{ .r = r, .g = g, .b = b };
}

pub fn colorRGBA(r: u8, g: u8, b: u8, a: u8) Self {
    return .{ .r = r, .g = g, .b = b, .a = a };
}

pub fn colorF(r: f32, g: f32, b: f32) Self {
    return .{ .r = @truncate(r * 255), .g = @truncate(g * 255), .b = @truncate(b * 255) };
}

pub fn colorFA(r: f32, g: f32, b: f32, a: f32) Self {
    return .{ .r = @truncate(r * 255), .g = @truncate(g * 255), .b = @truncate(b * 255), .a = @truncate(a * 255) };
}

pub fn getRealColor(color: Self) RealColor {
    const r: f32 = @as(f32, @floatFromInt(color.r)) / 255;
    const b: f32 = @as(f32, @floatFromInt(color.b)) / 255;
    const g: f32 = @as(f32, @floatFromInt(color.g)) / 255;
    const a: f32 = @as(f32, @floatFromInt(color.a)) / 255;

    return RealColor{ .r = r, .b = b, .g = g, .a = a };
}
