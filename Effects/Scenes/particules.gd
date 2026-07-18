extends Node2D

@onready var jump_p = $jump
@onready var wall_jump_p = $wall_land
@onready var slide_p = $slide
@onready var landing_p = $landing

func play_jump():
	jump_p.emitting = true

func play_wall_land(is_facing_right: bool, verticalVelocity: float, is_on_wall:bool):
	
	if verticalVelocity > 0 and is_on_wall:
		wall_jump_p.scale.x = 1 if is_facing_right else -1
		wall_jump_p.emitting = true
	else:
		wall_jump_p.emitting = false

func play_slide(is_facing_right: bool, is_slide):
	
	if is_slide:
		slide_p.scale.x = 1 if is_facing_right else -1
		slide_p.emitting = true
	else:
		slide_p.emitting = false

func play_landing():
	landing_p.emitting = true
