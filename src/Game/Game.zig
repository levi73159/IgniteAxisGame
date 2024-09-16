const std = @import("std");
const app = @import("../app.zig");

const Window = @import("../Display/Window.zig");
const GameObject = @import("GameObject.zig");
const Self = @This();

pub const Camera = @import("../Display/Camera.zig");
pub const Scene = @import("Scene.zig");
pub const SceneObject = @import("SceneObject.zig");

// A game is a struct with an array of scenes that can be loaded and unloaded at will

current_scene_index: usize,
scenes: std.ArrayList(Scene),
window: *Window, // the window that will be drawing the game on
mainCam: Camera,

pub fn init(window: *Window, mainCam: Camera, scenes: []const Scene) !Self {
    var instance = Self{
        .window = window,
        .scenes = try std.ArrayList(Scene).initCapacity(app.allocator(), scenes.len),
        .mainCam = mainCam,
        .current_scene_index = 0,
    };
    try instance.scenes.appendSlice(scenes);
    // now load scene zero
    try instance.scenes.items[0].load(&window.renderer);
    window.setTitle(instance.scenes.items[0].name);

    return instance;
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
    self.scenes.items[self.current_scene_index].unload();
    // deinit all
    for (self.scenes.items) |scene| {
        scene.deinit();
    }
    self.scenes.deinit();
}

pub fn update(self: *const Self) void {
    self.window.update();
}

pub fn updateScene(self: *Self) void {
    self.scenes.items[self.current_scene_index].update();
}

pub fn render(self: *const Self) void {
    self.window.render(self.mainCam);
}

pub fn load(self: *Self, index: usize) !void {
    if (self.current_scene_index == index) return; // avoid unecry loads

    const old_scene = &self.scenes.items[self.current_scene_index];
    old_scene.unload();
    self.current_scene_index = index;
    try self.scenes.items[index].load(&self.window.renderer);

    self.window.setTitle(self.scenes.items[index].name);
}

pub fn loadName(self: *Self, name: [*:0]const u8) !void {
    if (std.mem.eql(u8, name, self.scenes.items[self.current_scene_index].name)) return;

    const old_scene = &self.scenes.items[self.current_scene_index];
    old_scene.unload();

    for (self.scenes.items, 0..) |scene, index| {
        if (std.mem.eql(u8, name, scene.name)) {
            self.current_scene_index = index;
            try scene.load();
            self.window.setTitle(scene.name);
            break;
        }
    }
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
        if (std.mem.eql(u8, obj.tag, tag)){
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
    try self.scenes.items[self.current_scene_index].reload(&self.window.renderer);
}
