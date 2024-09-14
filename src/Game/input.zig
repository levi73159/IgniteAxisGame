const std = @import("std");
const glfw = @import("glfw");
const za = @import("zalgebra");
const Window = @import("../Display/Window.zig");

const Self = @This();

pub const Key = glfw.Key;
pub const KeysArray = std.EnumArray(glfw.Key, Action);
var keys: KeysArray = undefined;

const Action = enum(u2) {
    release = 0,
    press = 1,
    repeat = 2,
};

fn inputCallback(_: glfw.Window, key: Key, _: i32, action: glfw.Action, _: glfw.Mods) void {
    keys.set(key, switch (action) {
        .release => Action.release,
        .press => Action.press,
        .repeat => Action.repeat,
    });
}

pub fn init(win: *const Window) void {
    keys = KeysArray.initFill(.release);
    win.contex.setKeyCallback(inputCallback);
}

pub fn keyDown(key: Key) bool {
    return keys.get(key) == .press;
}

pub fn keyUp(key: Key) bool {
    return keys.get(key) == .release;
}

pub fn keyHold(key: Key) bool {
    const action = keys.get(key);
    return action == .press or action == .repeat;
}

pub fn getAxis(neg: Key, pos: Key) f32 {
    var axis: f32 = 0;

    if (keyHold(neg))
        axis -= 1;
    if (keyHold(pos))
        axis += 1;

    return axis;
}

pub fn getVec(up: Key, down: Key, left: Key, right: Key) za.Vec2 {
    var vec: za.Vec2 = za.Vec2.zero();

    if (keyHold(up))
        vec.yMut().* += -1;
    if (keyHold(down))
        vec.yMut().* += 1;

    if (keyHold(left))
        vec.xMut().* += -1;
    if (keyHold(right))
        vec.xMut().* += 1;

    return vec;
}
