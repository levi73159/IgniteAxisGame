const std = @import("std");
const ia = @import("ignite-axis");

const Self = @This();

speed: f32,
jump_height: f32,
gravity: f32,

velocity: ia.math.Vec2 = ia.math.Vec2.zero(),
is_grounded: bool = false,
is_jumping: bool = false,

game_object: GameObject, // the internal game object

pub fn init(renderer: *Renderer, pos: za.Vec2, speed: f32, jump_height: f32, gravity: f32, texture: Texture) !Self {
    return Self{
        .speed = speed,
        .jump_height = jump_height,
        .gravity = gravity,
        // zig fmt: off
        .game_object = try GameObject.initSquare(
            renderer, 
            pos, 
            za.Vec2.new(@as(f32, @floatFromInt(texture.width)), @as(f32, @floatFromInt(texture.height))),
            app.Color.white,
            texture,
            null
        ),
        // zig fmt: on
    };
}

pub fn initDefault(renderer: *Renderer, pos: za.Vec2, gravity: f32, texture: Texture) !Self {
    return init(renderer, pos, 200, 100, gravity, texture);
}

pub fn update(self: *Self, dt: f32) void {
    const move_dir = input.getAxis(.a, .d) * self.speed;
    self.velocity.xMut().* = move_dir;
    self.velocity.yMut().* += self.gravity * dt;

    if (self.is_grounded) {
        if (self.velocity.y() > 0) {
            self.velocity.yMut().* = 2;
        }
    }

    // now make it set is_jumping when we release space
    if (input.keyDown(.space)) {
        if (self.is_grounded and !self.is_jumping) {
            self.velocity.yMut().* = -std.math.sqrt(self.jump_height * 2.0 * self.gravity);
        }
        self.is_jumping = true;
    } else {
        self.is_jumping = false;
    }

    self.game_object.position().* = self.game_object.position().add(self.velocity.mul(za.Vec2.new(dt, dt)));
}

pub fn collison(self: *Self, obsticals: []const GameObject, dt: f32) void {
    self.is_grounded = false;

    // then check collison
    for (obsticals) |obstical| {
        if (self.game_object.isColliding(obstical)) {
            const offsetX: f32 = @abs(self.velocity.x()) * 2 * dt;
            const offsetY: f32 = @abs(self.velocity.y()) * 2 * dt;

            const objPos = self.game_object.position();
            const objScale = self.game_object.scale();
            const obstPos = obstical.position();
            const obstScale = obstical.scale();

            if (objPos.y() + objScale.y() - offsetY < obstPos.y()) {
                objPos.yMut().* = obstPos.y() - objScale.y();
                self.is_grounded = true;
            } else if (objPos.y() + offsetY > obstPos.y() + obstScale.y()) {
                objPos.yMut().* = obstPos.y() + obstScale.y();
                if (self.velocity.y() < 0) self.velocity.yMut().* = 2;
            } else if (objPos.x() + objScale.x() - offsetX < obstPos.x()) {
                objPos.xMut().* = obstPos.x() - objScale.x() - 0.2;
                self.velocity.xMut().* = 0;
            } else if (objPos.x() + offsetX > obstPos.x() + obstScale.x()) {
                objPos.xMut().* = obstPos.x() + obstScale.x() + 0.2;
                self.velocity.xMut().* = 0;
            }
        }
    }
}

pub inline fn isColliding(self: Self, other: GameObject) bool { return self.game_object.isColliding(other); }