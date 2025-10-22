/*
This file is the starting point of your game.

Some important procedures are:
- game_init_window: Opens the window
- game_init: Sets up the game state
- game_update: Run once per frame
- game_should_close: For stopping your game when close button is pressed
- game_shutdown: Shuts down game and frees memory
- game_shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
	pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g` global
	variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:fmt"
import "core:math/linalg"
import "core:slice"
import rl "vendor:raylib"

PIXEL_WINDOW_HEIGHT :: 180

Game_Memory :: struct {
	player_pos: rl.Vector2,
	player_idle_down: Animation,
	player_walk_down: Animation,	
	tree_tex: Texture,
	drawables: DrawableArray,
	some_number: int,
	run: bool,
	debug_draw: bool,
}

@(private="file")
g: ^Game_Memory

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {
		zoom = h/PIXEL_WINDOW_HEIGHT,
		target = g.player_pos,
		offset = { w/2 , h/2 + (2 * f32(g.player_walk_down.texture.height)) },
	}
}

ui_camera :: proc() -> rl.Camera2D {
	return {
		zoom = f32(rl.GetScreenHeight())/PIXEL_WINDOW_HEIGHT,
	}
}

update :: proc() {
	input: rl.Vector2
	drawables_reset()
	
	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		input.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
	}

	input = linalg.normalize0(input)
	g.player_pos += input * rl.GetFrameTime() * 100
	g.some_number += 1
	
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
	}
	if rl.IsKeyPressed(.F2) {
		g.debug_draw = !g.debug_draw
	}

	if (linalg.length(input) > 0) {
		animation_update(&g.player_walk_down)
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.DARKGREEN)

	rl.BeginMode2D(game_camera())
	draw_texture(g.tree_tex,  Rect{
		x = 0,
		y = 0,
		width = f32(g.tree_tex.width / 4),
		height = f32(g.tree_tex.height) / f32(2.3),
	}, Vec2{75, 0})
	draw_texture(g.tree_tex,  Rect{
		x = 0,
		y = 0,
		width = f32(g.tree_tex.width / 4),
		height = f32(g.tree_tex.height) / f32(2.3),
	}, Vec2{-75, 0})
	animation_draw(g.player_walk_down, g.player_pos)

	all_drawables := drawables_slice()
	slice.sort_by(all_drawables, proc(i, j: Drawable) -> bool {
		iy, jy: f32

		switch d in i {
			case DrawableTexture:
				iy = d.pos.y
			case DrawableRect:
		}
		switch d in j {
			case DrawableTexture:
				jy = d.pos.y
			case DrawableRect:
		}

		return iy < jy
	})
	for drawable in all_drawables {
		switch d in drawable {
			case DrawableTexture:
				source:= d.source
				if source.width == 0 {
					source.width = f32(d.tex.width)
				}
				if source.height == 0 {
					source.height = f32(d.tex.height)
				}

				rl.DrawTextureRec(d.tex, source, d.pos + d.offset, rl.WHITE)

				if g.debug_draw {
					rl.DrawCircleV(d.pos, 5, rl.YELLOW)
				}
			case DrawableRect:
		}
	}

	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())

	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	rl.DrawText(fmt.ctprintf("some_number: %v\nplayer_pos: %v", g.some_number, g.player_pos), 5, 5, 8, rl.WHITE)

	rl.EndMode2D()

	rl.EndDrawing()
}

@(export)
game_update :: proc() {
	update()
	draw()

	// Everything on tracking allocator is valid until end-of-frame.
	free_all(context.temp_allocator)
}

@(export)
game_init_window :: proc() {
	rl.SetConfigFlags({.WINDOW_RESIZABLE, .VSYNC_HINT})
	rl.InitWindow(1280, 720, "Odin + Raylib + Hot Reload template!")
	rl.SetWindowPosition(200, 200)
	rl.SetTargetFPS(500)
	rl.SetExitKey(nil)
}

@(export)
game_init :: proc() {
	g = new(Game_Memory)

	g^ = Game_Memory {
		run = true,
		debug_draw = false,
		some_number = 100,

		// You can put textures, sounds and music in the `assets` folder. Those
		// files will be part any release or web build.
		player_idle_down = animation_create(
			rl.LoadTexture("assets/Entities/Characters/Body_A/Animations/Idle_Base/Idle_Down-Sheet.png"), 4),
		player_walk_down = animation_create(
			rl.LoadTexture("assets/Entities/Characters/Body_A/Animations/Walk_Base/Walk_Down-Sheet.png"), 6),

		tree_tex = rl.LoadTexture("assets/Environment/Props/Static/Trees/Model_01/Size_05.png"),
	}

	game_hot_reloaded(g)
}

@(export)
game_should_run :: proc() -> bool {
	when ODIN_OS != .JS {
		// Never run this proc in browser. It contains a 16 ms sleep on web!
		if rl.WindowShouldClose() {
			return false
		}
	}

	return g.run
}

@(export)
game_shutdown :: proc() {
	rl.UnloadTexture(g.player_idle_down.texture)	
	rl.UnloadTexture(g.player_walk_down.texture)	
	free(g)
}

@(export)
game_shutdown_window :: proc() {
	rl.CloseWindow()
}

@(export)
game_memory :: proc() -> rawptr {
	return g
}

@(export)
game_memory_size :: proc() -> int {
	return size_of(Game_Memory)
}

@(export)
game_hot_reloaded :: proc(mem: rawptr) {
	g = (^Game_Memory)(mem)

	drawables_init(&g.drawables)
	// Here you can also set your own global variables. A good idea is to make
	// your global variables into pointers that point to something inside `g`.
}

@(export)
game_force_reload :: proc() -> bool {
	return rl.IsKeyPressed(.F5)
}

@(export)
game_force_restart :: proc() -> bool {
	return rl.IsKeyPressed(.F6)
}

// In a web build, this is called when browser changes size. Remove the
// `rl.SetWindowSize` call if you don't want a resizable game.
game_parent_window_size_changed :: proc(w, h: int) {
	rl.SetWindowSize(i32(w), i32(h))
}
