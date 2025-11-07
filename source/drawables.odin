package game

import "core:log"

DrawableOrigin :: enum {
    Center,
    BottomCenter,
}

DrawableRect :: struct {
    rect: Rect,
    color: Color,
    z: int,
}

DrawableTexture :: struct {
    texture: Texture,
    source: Rect,
    pos: Vec2,
    offset: Vec2,
    z: int,
}

DrawableText :: struct {
    text: cstring,
    pos: Vec2,
    z: int,
}

Drawable :: union {
    DrawableRect,
    DrawableTexture,
    DrawableText,
}

DrawableArray :: [4096]Drawable

@(private="file")
drawables: ^DrawableArray
@(private="file")
num_drawables: int

drawables_init :: proc(d: ^DrawableArray) {
    drawables = d
}

drawables_slice :: proc() -> []Drawable {
    return drawables[:num_drawables]
}

drawables_reset :: proc() {
    num_drawables = 0
}

add_drawable :: proc (d: Drawable) {
    if num_drawables == len(drawables) {
        log.error("too many drawables")
        return
    }

    drawables[num_drawables] = d
    num_drawables += 1
}

draw_texture_rec :: proc (
    texture: Texture,
    source: Rect,
    pos: Vec2,
    z: int = 0,
    origin: DrawableOrigin = .BottomCenter,
    flip_x: bool = false) {
    offset := get_texture_offset(source, origin, flip_x)
    add_drawable(DrawableTexture {
        texture = texture,
        source = source,
        pos = pos,
        offset = offset,
        z = z,
    })
}

draw_texture_pos :: proc (
    tex: Texture,
    pos: Vec2,
    z: int = 0,
    origin: DrawableOrigin = .BottomCenter,
    flip_x: bool = false) {
    offset := get_texture_offset({pos.x, pos.y, f32(tex.width), f32(tex.height)}, origin, flip_x)
    add_drawable(DrawableTexture {
        texture = tex,
        pos = pos,
        offset = offset,
        z = z,
    })
}

@(private="file")
get_texture_offset :: proc (source: Rect, origin: DrawableOrigin, flip_x: bool = false) -> Vec2 {
	offset: Vec2
    flipper : f32 = flip_x ? -1.0 : 1.0
    switch origin {
		case .Center:
			offset = {flipper*f32(-source.width)/2, f32(-source.height)/2}
		case .BottomCenter:
			offset = {flipper*f32(-source.width)/2, f32(-source.height)}
	}

    return offset
}

draw_rect :: proc (rect: Rect, color: Color) {
    add_drawable(DrawableRect {
        rect = rect,
        color = color,
    })
}

draw_text :: proc (text: cstring, pos: Vec2, z: int) {
    add_drawable(DrawableText {
        text = text,
        pos = pos,
        z = z,
    })
}
