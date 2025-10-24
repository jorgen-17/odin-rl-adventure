package game

import "core:log"

DrawableOrigin :: enum {
    Center,
    BottomCenter,
}

DrawableRect :: struct {
    rect: Rect,
    color: Color,
}

DrawableTexture :: struct {
    tex: Texture,
    source: Rect,
    pos: Vec2,
    offset: Vec2,
}

Drawable :: union {
    DrawableRect,
    DrawableTexture,
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

draw_texture_rec :: proc (tex: Texture, source: Rect, pos: Vec2, origin: DrawableOrigin = .BottomCenter) {
    offset := get_texture_offset(source, origin)
    add_drawable(DrawableTexture {
        tex = tex,
        source = source,
        pos = pos,
        offset = offset,
    })
}

draw_texture_pos :: proc (tex: Texture, pos: Vec2, origin: DrawableOrigin = .BottomCenter) {
    offset := get_texture_offset({pos.x, pos.y, f32(tex.width), f32(tex.height)}, origin)
    add_drawable(DrawableTexture {
        tex = tex,
        pos = pos,
        offset = offset,
    })
}

@(private="file")
get_texture_offset :: proc (source: Rect, origin: DrawableOrigin) -> Vec2 {
	offset: Vec2
    switch origin {
		case .Center:
			offset = {f32(-source.width)/2, f32(-source.height)/2}
		case .BottomCenter:
			offset = {f32(-source.width)/2, f32(-source.height)}
	}

    return offset
}

draw_texture :: proc { draw_texture_rec, draw_texture_pos }

draw_rect :: proc (rect: Rect, color: Color) {
    add_drawable(DrawableRect {
        rect = rect,
        color = color,
    })
}
