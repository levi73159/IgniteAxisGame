const za = @import("zalgebra");
const app = @import("app.zig");
const std = @import("std");
const Game = @import("Game/Game.zig");
const Texture = @import("Display/Texture.zig");
const Player = @import("Game/Player.zig");
const Scene = Game.Scene;

const gravity: f32 = 723.19;

var player: Player = undefined; // should get loaded in at load
var platforms: []Game.GameObject = undefined;
var win_pole: ?Game.GameObject = null;

pub fn onStart(game: *Game, _: f32) anyerror!void {
    const player_texture = try Texture.init(app.allocator(), "res/Player.png", 1);
    player = try Player.initDefault(&game.window.renderer, za.Vec2.zero(), gravity, player_texture);
}

pub fn onExit(_: *Game, _: f32) anyerror!void {
    player.game_object.texture.deinit();
}

pub fn onLoad(game: *Game, _: f32) anyerror!void {
    const allocator = app.allocator();

    player.game_object.position().* = za.Vec2.zero();
    game.mainCam.focus(player.game_object.position().*);

    platforms = try game.getObjectTagAlloc(allocator, "Platform");

    win_pole = game.getObject("Win");
    if (win_pole == null) {
        std.log.warn("No Win Pole: can't find object \"Win\"", .{});
    }
}

pub fn onUnload(_: *Game, _: f32) anyerror!void {
    app.allocator().free(platforms);
}

pub fn onUpdate(game: *Game, dt: f32) anyerror!void {
    
    player.update(dt);
    player.collison(platforms, dt);

    if (win_pole) |win_area| {
        if (player.isColliding(win_area)) {
            try game.load(1);
            return;
        }
    }

    // focuos then clamp the bottom of the cam viewport to the ground end
    const bottom_of_ground = platforms[0].internal.postion.y() + platforms[0].internal.scale.y();

    const focus_point = player.game_object.position().add(player.velocity.scale(0.1));
    game.mainCam.focusSmooth(focus_point, (@abs(player.velocity.x()) + 50) * dt);
    game.mainCam.postion.yMut().* = std.math.clamp(game.mainCam.postion.y(), 0, bottom_of_ground - game.mainCam.viewport().y());
}
