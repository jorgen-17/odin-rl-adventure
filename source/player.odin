package game

Player_Action :: enum {
    Idle,
    Walking,
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
	idle_down: Animation,
	idle_up: Animation,
	idle_right: Animation,
	walk_down: Animation,	
	walk_up: Animation,	
	walk_right: Animation,	
}
