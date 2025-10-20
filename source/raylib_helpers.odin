package game

import rl "vendor:raylib"

Tex :: rl.Texture
Color :: rl.Color

texture_rect :: proc(tex: Tex, flip_x: bool) -> Rect {
	return {
		x = 0,
		y = 0,
		width = flip_x ? - f32(tex.width) : f32(tex.width),
		height = f32(tex.height),
	}
}