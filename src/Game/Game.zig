const std = @import("std");
const app = @import("../app.zig");

const Window = @import("../Display/Window.zig");
const Self = @This();

pub const Camera = @import("../Display/Camera.zig");
pub const Scene = @import("Scene.zig");
pub const SceneObject = @import("SceneObject.zig");
pub const GameObject = @import("GameObject.zig");

// we don't need dt but we gonna keep it for simpicity
// but we can access it in game
pub const GameEventFn = *const fn (game: *Self, dt: f32) anyerror!void;

// A game is a struct with an array of scenes that can be loaded and unloaded at will
current_scene_index: usize,
scenes: std.ArrayList(Scene),
window: *Window, // the window that will be drawing the game on
mainCam: Camera,

time: f32 = 0,
delta_time: f32 = 0,

is_running: bool = false,

// the order will specify the order they are called
// start (game start) -> load (scene load) -> update (every frame) -> unload (scene unload) -> exit (game exit)
start_event: ?GameEventFn = null, // game start
load_event: ?GameEventFn = null, // scene load
update_event: ?GameEventFn = null, // every frame
unload_event: ?GameEventFn = null, // scene unload
exit_event: ?GameEventFn = null, // game exit

pub fn init(window: *Window, mainCam: Camera, scenes: []const Scene) !Self {
    var instance = Self{
        .window = window,
        .scenes = try std.ArrayList(Scene).initCapacity(app.allocator(), scenes.len),
        .mainCam = mainCam,
        .current_scene_index = 0,
    };
    try instance.scenes.appendSlice(scenes);

    return instance;
}

pub fn start(self: *Self) !void {
    self.callEvent(self.start_event);

    // now load scene zero
    try self.loadSceneWithoutUnload(self.current_scene_index);

    const dt_low_limit: f32 = 1.0 / 90.0; // 90 fps
    const dt_high_limit: f32 = 1.0 / 10.0; // 10 fps

    self.is_running = true;

    var timer = try std.time.Timer.start();
    while (!self.window.shouldClose() and self.is_running) {
        self.delta_time = blk: {
            var dt: f32 = @as(f32, @floatFromInt(timer.lap())) / std.time.ns_per_s;
            if (dt > dt_high_limit) {
                dt = dt_high_limit;
            } else if (dt < dt_low_limit) {
                dt = dt_low_limit;
            }
            break :blk dt;
        };
        self.time = @as(f32, @floatFromInt(timer.read())) / std.time.ns_per_s;

        self.update();
        self.render();
    }

    self.callEvent(self.unload_event);
    self.currentScene().unload();

    self.callEvent(self.exit_event);
}

pub fn addScene(self: *Self, scene: Scene) !void {
    try self.scenes.append(scene);
}

pub fn removeScene(self: *Self, index: usize) void {
    if (self.scenes.items.len == 0) return;
    if (self.current_scene_index == index) {
        self.scenes.items[index].unload();
    }
    self.scenes.items[index].deinit();
    self.scenes.orderedRemove(index);
}

pub fn deinit(self: *Self) void {
    // only need to unload current scene
    self.currentScene().unload();

    // deinit all
    for (self.scenes.items) |scene| {
        scene.deinit();
    }
    self.scenes.deinit();
}

pub fn update(self: *Self) void {
    self.window.update();
    self.callEvent(self.update_event);
}

// useful to call event so we don't have a lot of the same code
inline fn callEvent(self: *Self, maybe_event: ?GameEventFn) void {
    if (maybe_event) |event| {
        event(self, self.delta_time) catch |err| {
            std.debug.panic("Error on event: {any}", .{err});
        };
    }
}

fn getEvent(comptime name: []const u8, namespace: type) ?GameEventFn {
    if (comptime @hasDecl(namespace, name)) {
        switch (@typeInfo(@TypeOf(@field(namespace, name)))) {
            .Fn => {
                return @field(namespace, name);
            },
            else => @compileError("Event Must be of type function"),
        }
    }
    return null;
}

pub fn setEvents(self: *Self, namespace: type) void {
    const start_event_name = "onStart";
    const exit_event_name = "onExit";
    const load_event_name = "onLoad";
    const unload_event_name = "onUnload";
    const update_event_name = "onUpdate";

    self.start_event = getEvent(start_event_name, namespace);
    self.exit_event = getEvent(exit_event_name, namespace);
    self.load_event = getEvent(load_event_name, namespace);
    self.unload_event = getEvent(unload_event_name, namespace);
    self.update_event = getEvent(update_event_name, namespace);
}

pub fn updateScene(self: *Self) void {
    self.scenes.items[self.current_scene_index].update();
}

pub fn render(self: *const Self) void {
    self.window.render(self.mainCam);
}

pub fn load(self: *Self, index: usize) !void {
    // if (self.current_scene_index == index) return; // avoid unecry loads

    self.callEvent(self.unload_event);
    self.currentScene().unload();
    try self.loadSceneWithoutUnload(index);
}

fn loadSceneWithoutUnload(self: *Self, index: usize) !void {
    // No unload event triggered here
    self.current_scene_index = index;
    try self.scenes.items[index].load(&self.window.renderer);

    self.window.setTitle(self.scenes.items[index].name);
    self.callEvent(self.load_event);
}

pub fn loadName(self: *Self, name: [*:0]const u8) !void {
    if (std.mem.eql(u8, name, self.currentScene().name)) return;

    self.callEvent(self.unload_event);
    self.currentScene().unload();

    for (self.scenes.items, 0..) |scene, index| {
        if (std.mem.eql(u8, name, scene.name)) {
            self.current_scene_index = index;
            try scene.load();
            self.window.setTitle(scene.name);
            break;
        }
    }
    self.callEvent(self.load_event);
}

/// gets a game object from the current scene and returns it
pub fn getObject(self: *const Self, name: []const u8) ?GameObject {
    for (self.currentScene().objects) |*obj| {
        if (std.mem.eql(u8, obj.name, name))
            return obj.object.?;
    }
    return null;
}

/// gets a game object fro, the current scene and returns it, returns null if index is out of range, warning becarefull when you unload the scene because then the internal
/// rendering object will be freed and undefined
pub fn getObjectAtIndex(self: *const Self, index: usize) ?GameObject {
    const current_scene = self.currentScene();
    return if (index < current_scene.objects.len)
        current_scene.objects[index].object.?
    else
        null;
}

pub fn getObjectTag(self: *const Self, tag: []const u8, buffer: []GameObject) []GameObject {
    var len: usize = 0;
    for (self.currentScene().objects) |*obj| {
        if (std.mem.eql(u8, obj.tag, tag)) {
            buffer[len] = obj.object orelse unreachable;
            len += 1;
        }
    }
    return buffer[0..len];
}

pub fn getObjectTagAlloc(self: *const Self, allocator: std.mem.Allocator, tag: []const u8) ![]GameObject {
    var len: usize = 0;
    var objects = try allocator.alloc(GameObject, 256); // allocates 256 game object of memory
    errdefer allocator.free(objects);

    for (self.currentScene().objects) |*obj| {
        if (std.mem.eql(u8, obj.tag, tag)) {
            objects[len] = obj.object orelse return error.ObjNotInit;
            len += 1;
        }
    }
    return allocator.realloc(objects, len);
}

// returns a pointer to current scene
pub fn currentScene(self: *const Self) *Scene {
    return &self.scenes.items[self.current_scene_index];
}

pub fn reload(self: *Self) !void {
    self.callEvent(self.unload_event);
    try self.scenes.items[self.current_scene_index].reload(&self.window.renderer);
    self.callEvent(self.load_event);
}
