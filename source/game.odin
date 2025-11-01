package game

import "core:fmt"
import "core:math/linalg"
import "core:slice"
import rl "vendor:raylib"

PIXEL_WINDOW_HEIGHT :: 180

NPC :: struct {
	animation: Animation,
	pos: Vec2,
}

Icon :: struct {
	texture: Texture,
	pos: Vec2,
	z: int,
}

Icons :: struct {
	speech_bubble: Icon
}

Game_Memory :: struct {
	player: Player,
	tree_texture: Texture,
	drawables: DrawableArray,
	npcs: HandleArray(NPC, 128),
	icons: Icons,
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
		target = g.player.pos,
		offset = { w/2 , h/2 + (2 * f32(g.player.walk_down.texture.height)) },
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
		g.player.direction = .UP
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.y += 1
		g.player.direction = .DOWN
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
		g.player.direction = .LEFT
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
		g.player.direction = .RIGHT
	}

	input = linalg.normalize0(input)
	g.player.pos += input * rl.GetFrameTime() * 100
	g.some_number += 1
	
	if rl.IsKeyPressed(.ESCAPE) {
		g.run = false
	}
	if rl.IsKeyPressed(.F2) {
		g.debug_draw = !g.debug_draw
	}

	if (linalg.length(input) > 0) {
		switch g.player.direction {
			case .DOWN:
				animation_update(&g.player.walk_down)
			case .UP:
				animation_update(&g.player.walk_up)
			case .RIGHT, .LEFT:
				animation_update(&g.player.walk_right)
		}
		g.player.action = .Walking
	} else {
		switch g.player.direction {
			case .DOWN:
				animation_update(&g.player.idle_down)
			case .UP:
				animation_update(&g.player.idle_up)
			case .RIGHT, .LEFT:
				animation_update(&g.player.idle_right)
		}
		g.player.action = .Idle
	}

	npcs_iter := ha_make_iter(&g.npcs)
	for npc in ha_iter_ptr(&npcs_iter) {
		animation_update(&npc.animation)
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.DARKGREEN)

	rl.BeginMode2D(game_camera())

	draw_texture_rec(g.tree_texture,  Rect{
		x = 0,
		y = 0,
		width = f32(g.tree_texture.width / 4),
		height = f32(g.tree_texture.height) / f32(2.3),
	}, Vec2{75, 0})
	draw_texture_rec(g.tree_texture,  Rect{
		x = 0,
		y = 0,
		width = f32(g.tree_texture.width / 4),
		height = f32(g.tree_texture.height) / f32(2.3),
	}, Vec2{-75, 0})

	switch g.player.action {
		case .Idle:
			switch g.player.direction {
				case .DOWN:
					animation_draw(g.player.idle_down, g.player.pos)
				case .UP:
					animation_draw(g.player.idle_up, g.player.pos)
				case .RIGHT:
					animation_draw(g.player.idle_right, g.player.pos)
				case .LEFT:
					animation_draw(g.player.idle_right, g.player.pos, true)
			}
		case .Walking:
			switch g.player.direction {
				case .DOWN:
					animation_draw(g.player.walk_down, g.player.pos)
				case .UP:
					animation_draw(g.player.walk_up, g.player.pos)
				case .RIGHT:
					animation_draw(g.player.walk_right, g.player.pos)
				case .LEFT:
					animation_draw(g.player.walk_right, g.player.pos, true)
			}
	}

	TalkMaxDistance :: 32
	nearest_distance_to_player := max(f32)
	nearest_npc_handle: Handle(NPC)

	npcs_iter := ha_make_iter(&g.npcs)
	for npc, handle_npc in ha_iter(&npcs_iter) {
		distance_to_player := linalg.length(npc.pos - g.player.pos)
		if distance_to_player < nearest_distance_to_player && distance_to_player < TalkMaxDistance {
			nearest_npc_handle = handle_npc
			nearest_distance_to_player = distance_to_player
		}
		animation_draw(npc.animation, npc.pos)
	}

	if nearest_distance_to_player < TalkMaxDistance {
		nearest_npc, _ := ha_get(g.npcs, nearest_npc_handle)
		draw_texture_pos(g.icons.speech_bubble.texture, (nearest_npc.pos + { 0.0, -30.0 }), g.icons.speech_bubble.z)
	}

	all_drawables := drawables_slice()
	slice.sort_by(all_drawables, proc(i, j: Drawable) -> bool {
		iy, jy: f32
		iz, jz: int

		switch d in i {
			case DrawableTexture:
				iy = d.pos.y
				iz = d.z
			case DrawableRect:
				iy = d.rect.y
				iz = d.z
		}
		switch d in j {
			case DrawableTexture:
				jy = d.pos.y
				jz = d.z
			case DrawableRect:
				jy = d.rect.y
				jz = d.z
		}

		return iy < jy && iz < jz
	})
	for drawable in all_drawables {
		switch d in drawable {
			case DrawableTexture:
				source:= d.source
				if source.width == 0 {
					source.width = f32(d.texture.width)
				}
				if source.height == 0 {
					source.height = f32(d.texture.height)
				}

				rl.DrawTextureRec(d.texture, source, d.pos + d.offset, rl.WHITE)

				if g.debug_draw {
					rl.DrawCircleV(d.pos, 5, rl.YELLOW)
				}
			case DrawableRect:
				rl.DrawRectangleRec(d.rect, d.color)

				if g.debug_draw {
					rl.DrawCircleV({d.rect.x, d.rect.y}, 5, rl.YELLOW)
				}
		}
	}

	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())

	// NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
	// cleared at the end of the frame by the main application, meaning inside
	// `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
	rl.DrawText(fmt.ctprintf("some_number: %v\nplayer_pos: %v", g.some_number, g.player.pos), 5, 5, 8, rl.WHITE)

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
		player = Player {
			action = .Idle,
			direction = .DOWN,

			idle_down = animation_create(
				rl.LoadTexture("assets/Entities/Characters/Body_A/Animations/Idle_Base/Idle_Down-Sheet.png"), 4),
			idle_up = animation_create(
				rl.LoadTexture("assets/Entities/Characters/Body_A/Animations/Idle_Base/Idle_Up-Sheet.png"), 4),
			idle_right = animation_create(
				rl.LoadTexture("assets/Entities/Characters/Body_A/Animations/Idle_Base/Idle_Side-Sheet.png"), 4),

			walk_down = animation_create(
				rl.LoadTexture("assets/Entities/Characters/Body_A/Animations/Walk_Base/Walk_Down-Sheet.png"), 6),
			walk_up = animation_create(
				rl.LoadTexture("assets/Entities/Characters/Body_A/Animations/Walk_Base/Walk_Up-Sheet.png"), 6),
			walk_right = animation_create(
				rl.LoadTexture("assets/Entities/Characters/Body_A/Animations/Walk_Base/Walk_Side-Sheet.png"), 6),
		},

		tree_texture = rl.LoadTexture("assets/Environment/Props/Static/Trees/Model_01/Size_05.png"),

		icons = Icons {
			speech_bubble = Icon {
				texture = rl.LoadTexture("assets/Icons/speech_bubble.png"),
				pos = { 0.0, 0.0 },
				z = 1,
			},
		},
	}

	knight := NPC {
		animation = animation_create(rl.LoadTexture("assets/Entities/Npc's/Knight/Idle/Idle-Sheet.png"), 4),
		pos = {-80, 10},
	}

	ha_add(&g.npcs, knight)

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
	rl.UnloadTexture(g.player.idle_down.texture)
	rl.UnloadTexture(g.player.idle_up.texture)
	rl.UnloadTexture(g.player.idle_right.texture)
	rl.UnloadTexture(g.player.walk_down.texture)
	rl.UnloadTexture(g.player.walk_up.texture)
	rl.UnloadTexture(g.player.walk_right.texture)

	npcs_iter := ha_make_iter(&g.npcs)
	for npc in ha_iter(&npcs_iter) {
		rl.UnloadTexture(npc.animation.texture)
	}

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
