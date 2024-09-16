const std = @import("std");
const gl = @import("gl");
const za = @import("zalgebra");
const app = @import("../app.zig");

const Texture = @import("../Display/Texture.zig");
const Shader = @import("../Display/Shader.zig");
const Object = @import("../Display/Object.zig");
const Renderer = @import("../Display/Renderer.zig");
const Color = @import("../Display/Color.zig");
const Self = @This();

pub const GameObject = @import("GameObject.zig");
pub const SceneObject = @import("SceneObject.zig");

// A scene is struct with Array of SceneObject which is a basic structure whith a GameObject and data
name: [:0]const u8,
objects: []SceneObject, // heap allocated
allocator: std.mem.Allocator,

/// panics if OutOfMemory
pub fn init(allocator: std.mem.Allocator, name: [:0]const u8, objects: []const SceneObject) Self {
    return Self{
        .name = allocator.dupeZ(u8, name) catch std.debug.panic("Not Enough Memory To Dup", .{}),
        .objects = allocator.dupe(SceneObject, objects) catch std.debug.panic("Not Enough Memory To Dup", .{}),
        .allocator = allocator,
    };
}

const ObjectJsonData = struct {
    const VerticesType = union(enum) {
        const VerticesInfo = struct {
            vert: []const f32,
            indi: []const u32,
            layout: ?[]const u8,
        };

        predefine: []const u8,
        vertices: VerticesInfo,
        clone: usize,
        existing: struct { buffer_id: u32, layout: ?[]const u8 },
    };

    name: []const u8,
    tag: []const u8,
    vertices: VerticesType,
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    color: []const u8,
    texture: []const u8,
    shader: ?[]const u8,
};

const SceneJsonData = struct {
    name: [:0]const u8,
    objects: []const ObjectJsonData,
};

pub fn fromFile(allocator: std.mem.Allocator, filename: []const u8, args: anytype) !Self {
    const ArgsType = @TypeOf(args);
    const args_info = @typeInfo(ArgsType);
    if (args_info != .Struct) {
        @compileError("expected tuple or struct argument, found " ++ @typeName(ArgsType));
    }

    const args_fields = args_info.Struct.fields;

    // get the file
    const full_path = try std.fmt.allocPrint(allocator, "res/{s}.scene", .{filename});
    defer allocator.free(full_path);

    const file = try std.fs.cwd().openFile(full_path, .{});
    defer file.close();

    const read_buf = try file.readToEndAlloc(allocator, 2048 * 2048);
    defer allocator.free(read_buf);

    const scene_data = try std.json.parseFromSlice(SceneJsonData, allocator, read_buf, .{});
    defer scene_data.deinit();

    var objects: [256]SceneObject = undefined;

    for (scene_data.value.objects, 0..) |data, i| {
        const color: Color = blk: {
            if (data.color[0] == '#') {
                const red_hex = data.color[1..3];
                const green_hex = data.color[3..5];
                const blue_hex = data.color[5..7];

                const red = try std.fmt.parseInt(u8, red_hex, 16);
                const green = try std.fmt.parseInt(u8, green_hex, 16);
                const blue = try std.fmt.parseInt(u8, blue_hex, 16);
                break :blk Color.colorRGB(red, green, blue);
            }

            if (std.mem.eql(u8, data.color, "red")) break :blk Color.red;
            if (std.mem.eql(u8, data.color, "green")) break :blk Color.green;
            if (std.mem.eql(u8, data.color, "blue")) break :blk Color.blue;
            if (std.mem.eql(u8, data.color, "white")) break :blk Color.white;
            if (std.mem.eql(u8, data.color, "black")) break :blk Color.black;

            break :blk Color.colorRGB(255, 155, 155);
        };

        var texture: ?Texture = null;
        var shader: ?Shader = null;
        var layout: ?Object.Layout = null; // can be null and will be null and null is default
        inline for (args_fields) |field| {
            if (field.type == Texture and std.mem.eql(u8, data.texture, field.name)) {
                texture = @field(args, field.name);
            } else if (data.shader != null and field.type == Shader and std.mem.eql(u8, data.shader.?, field.name)) {
                shader = @field(args, field.name);
            } else if (field.type == Object.Layout) {
                if (data.vertices == .existing and data.vertices.existing.layout != null and std.mem.eql(u8, data.vertices.existing.layout.?, field.name)) {
                    layout = @field(args, field.name);
                } else if (data.vertices == .vertices and data.vertices.vertices.layout != null and std.mem.eql(u8, data.vertices.vertices.layout.?, field.name)) {
                    layout = @field(args, field.name);
                }
            }
        }

        if (texture == null) return error.TextureNotFound;
        if (data.shader != null and shader == null) return error.ShaderNotFound;

        switch (data.vertices) {
            .predefine => |object| {
                if (std.mem.eql(u8, object, "Square")) {
                    // zig fmt: off
                    objects[i] = SceneObject.initSquare(
                        data.name, data.tag,
                        za.Vec2.new(data.x, data.y), 
                        za.Vec2.new(data.w, data.h), 
                        color, 
                        texture.?, 
                        shader
                    );
                    // zig fmt: on
                } else {
                    return error.InvalidPredefineVertex;
                }
            },
            .clone => |index| {
                // zig fmt: off
                objects[i] = SceneObject.initClone(data.name, data.tag,
                        za.Vec2.new(data.x, data.y), 
                        za.Vec2.new(data.w, data.h), 
                        color, 
                        texture.?, 
                        index
                    );
                // zig fmt: on
            },
            .existing => |existing| {
                // zig fmt: off
                objects[i] = SceneObject.initExisting(data.name, data.tag,
                        za.Vec2.new(data.x, data.y), 
                        za.Vec2.new(data.w, data.h), 
                        color, 
                        texture.?, 
                        existing.buffer_id,
                        shader,
                        layout orelse app.defaultLayout().*
                    );
                // zig fmt: on
            },
            .vertices => |vertsInfo| {
                // zig fmt: off
                objects[i] = SceneObject.init(data.name, data.tag,
                        za.Vec2.new(data.x, data.y), 
                        za.Vec2.new(data.w, data.h), 
                        color, 
                        texture.?, 
                        shader,
                        vertsInfo.vert,
                        vertsInfo.indi,
                        layout orelse app.defaultLayout().*
                );
                // zig fmt: on
            },
        }
    }

    return Self.init(allocator, scene_data.value.name, objects[0..scene_data.value.objects.len]);
}

pub fn load(self: *Self, renderer: *Renderer) !void {
    for (self.objects) |*obj| {
        try obj.load(renderer, self.objects);
    }
}

// updates all the scene game objects if have any
pub fn update(self: *Self) void {
    for (self.objects) |*obj| {
        if (obj.object != null) {
            obj.object.?.update();
        }
    }
}

// unload the scene
pub fn unload(self: *Self) void {
    for (self.objects) |*obj| {
        obj.unload();
    }
}

pub fn reload(self: *Self, renderer: *Renderer) !void {
    for (self.objects) |*obj| {
        obj.unload();
        try obj.load(renderer);
    }
}

// should unload objects first if objects are loaded
pub fn deinit(self: *const Self) void {
    for (self.objects) |obj| {
        obj.deinit();
    }
    self.allocator.free(self.name);
    self.allocator.free(self.objects);
}
