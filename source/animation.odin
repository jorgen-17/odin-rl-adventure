package game

import rl "vendor:raylib"
import "core:log"

Animation :: struct {
    texture: Tex,
    num_frames: int,
    current_frame: int,
    frame_timer: f32,
}

animation_create :: proc(tex: Tex, num_frames: int) -> Animation {
    return Animation {
        texture = tex,
        num_frames = num_frames,
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

animation_draw :: proc(a: Animation, pos: Vec2) {
    if a.num_frames == 0 {
        log.error("animation has 0 frames")
        return
    }

    width := f32(a.texture.width)
    height := f32(a.texture.height)

    frame_width := width / f32(a.num_frames)
    source := Rect{
        x = f32(a.current_frame) * frame_width,
        y = 0,
        width = frame_width,
        height = height,
    }

    rl.DrawTextureRec(a.texture, source, pos, rl.WHITE)
}