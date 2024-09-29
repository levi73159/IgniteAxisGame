const std = @import("std");
const ia = @import("ignite-axis");
const Player = @import("Player.zig");

const gravity: f32 = 723.19;

var player: Player = undefined; // should get loaded in at load
var platforms: []ia.GameObject = undefined;
var spikes: []ia.GameObject = undefined;
var win_pole: ?ia.GameObject = null;

pub fn onStart(game: *ia.Game, _: f32) anyerror!void {
    const player_texture = try ia.Texture.init(ia.allocator(), "res/Player.png");
    player = try Player.initDefault(&game.window.renderer, ia.math.Vec2.zero(), gravity, player_texture);
}

pub fn onExit(_: *ia.Game, _: f32) anyerror!void {
    player.game_object.texture.deinit(ia.allocator());
}

pub fn onLoad(game: *ia.Game, _: f32) anyerror!void {
    const allocator = ia.allocator();

    player.game_object.position().* = ia.math.Vec2.zero();
    player.velocity = ia.math.Vec2.zero();

    game.mainCam.focus(player.game_object.position().*);

    platforms = try game.getObjectTagAlloc(allocator, "Platform");
    spikes = try game.getObjectTagAlloc(allocator, "Death");

    win_pole = game.getObject("Win");
    if (win_pole == null) {
        std.log.warn("No Win Pole: can't find object \"Win\"", .{});
    }
}

pub fn onUnload(_: *ia.Game, _: f32) anyerror!void {
    ia.allocator().free(platforms);
    ia.allocator().free(spikes);
}

pub fn onUpdate(game: *ia.Game, dt: f32) anyerror!void {
    player.update(dt);
    player.collison(platforms, dt);

    if (win_pole) |win_area| {
        if (player.isColliding(win_area)) {
            try game.load(1);
            return;
        }
    }

    // check if we should die
    for (spikes) |spike| {
        if (player.isColliding(spike)) {
            try game.reload();
            return;
        }
    }

    // focuos then clamp the bottom of the cam viewport to the ground end
    const bottom_of_ground = platforms[0].internal.postion.y() + platforms[0].internal.scale.y();

    const focus_point = player.game_object.position().add(player.velocity.scale(0.1));
    game.mainCam.focusSmooth(focus_point, (@abs(player.velocity.x()) + 50) * dt);
    game.mainCam.postion.yMut().* = std.math.clamp(game.mainCam.postion.y(), 0, bottom_of_ground - game.mainCam.viewport().y());
}
