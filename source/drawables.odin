package game

import "core:log"

DrawableOrigin :: enum {
    Center,
    BottomCenter,
}

DrawableRect :: struct {
}

DrawableTexture :: struct {
    tex: Texture,
    source: Rect,
    pos: Vec2,
    origin: DrawableOrigin,
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
    add_drawable(DrawableTexture {
        tex = tex,
        source = source,
        pos = pos,
        origin = origin,
    })
}

draw_texture_pos :: proc (tex: Texture, pos: Vec2, origin: DrawableOrigin = .BottomCenter) {
    add_drawable(DrawableTexture {
        tex = tex,
        pos = pos,
        origin = origin,
    })
}

draw_texture :: proc { draw_texture_rec, draw_texture_pos }