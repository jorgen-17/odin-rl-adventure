package game

Player_Action :: enum {
    Idle,
    Walking,
    Melee_Slice,
}

Player_Direction :: enum {
    UP,
    DOWN,
    LEFT,
    RIGHT,
}

Player :: struct {
    pos: Vec2,
    direction: Player_Direction,
    action: Player_Action,
    nearest_npc: Handle(NPC),
    distance_nearest_npc: f32,
    talking: bool,
    idle_down: Animation,
    idle_up: Animation,
    idle_right: Animation,
    walk_down: Animation,	
    walk_up: Animation,	
    walk_right: Animation,	
    melee_slice_up: Animation,
    melee_slice_down: Animation,
    melee_slice_right: Animation,
}
