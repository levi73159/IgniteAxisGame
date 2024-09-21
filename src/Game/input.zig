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

pub const CallbackFuncT = *fn(key: Key, action: Action) void;
var callback: ?CallbackFuncT = null; // right now we have one function that get call at everthing, were gonna eventually make that 25 or so

fn inputCallback(_: glfw.Window, key: Key, _: i32, action: glfw.Action, _: glfw.Mods) void {
    // const prev = keys.get(key);
    keys.set(key, switch (action) {
        .release => Action.release,
        .press => Action.press,
        .repeat => Action.repeat,
    });
    if (callback) |cb| {
        cb(key, keys.get(key));
    }
}

pub fn setInputCallback(callback_function: CallbackFuncT) void {
    callback = callback_function;
}

pub fn init(win: *const Window) void {
    keys = KeysArray.initFill(.release);
    win.contex.setKeyCallback(inputCallback);
}

/// notice this function doesn't allways work when a key is press, it might be press and held down but still will return true
/// this because a key intrupts a key that press
/// 
/// in order to fix this, monitor the key state, in your code, make a variable keeping track of your last code of the state
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
