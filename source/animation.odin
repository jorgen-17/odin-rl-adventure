package game

import rl "vendor:raylib"
import "core:log"

Animation :: struct {
    texture: Texture,
    num_frames: int,
    current_frame: int,
    frame_timer: f32,
    origin: DrawableOrigin,
}

animation_create :: proc(tex: Texture, num_frames: int, origin: DrawableOrigin = .BottomCenter) -> Animation {
    return Animation {
        texture = tex,
        num_frames = num_frames,
        origin = origin
    }
}

animation_update :: proc(a: ^Animation) {
    a.frame_timer -= rl.GetFrameTime()
    
    if a.frame_timer <= 0 {
        a.frame_timer = 0.1
        a.current_frame += 1

        if a.current_frame >= a.num_frames {
            a.current_frame = 0
        }
    }
    
}

animation_draw :: proc(a: Animation, pos: Vec2, flip_x: bool = false) {
    if a.num_frames == 0 {
        log.error("animation has 0 frames")
        return
    }

    width := f32(a.texture.width)
    height := f32(a.texture.height)

    frame_width := width / f32(a.num_frames)
    // flipper : f32 = flip_x ? -1.0 : 1.0
    // rect_width := flipper * frame_width
    source := Rect{
        x = f32(a.current_frame) * frame_width,
        y = 0,
        width = frame_width,
        height = height,
    }

    draw_texture(a.texture, source, pos, a.origin)
}