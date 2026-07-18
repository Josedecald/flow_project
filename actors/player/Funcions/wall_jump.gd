extends Node
class_name WallJumpSystem

signal wall_jumped

@export var jump_x := 200.0
@export var jump_x_max := 350.0

@export var jump_y := -300.0
@export var jump_y_max := -500.0

@export var duration := 0.5

@onready var right_col = $"../../wall_collision/right_col"
@onready var left_col = $"../../wall_collision/left_col"

var actual_jump_x := 0.0
var actual_jump_y := 0.0

var is_walljumping := false
var timer := 0.0


func update_stats(flow: float):

	actual_jump_x = lerp(jump_x, jump_x_max, flow / 100.0)
	actual_jump_y = lerp(jump_y, jump_y_max, flow / 100.0)


func update(
	velocity: Vector2,
	delta: float,
	on_floor: bool
) -> Vector2:

	if is_touching_wall() and !on_floor:
		velocity.y = min(velocity.y,30)

	if is_touching_wall() and !on_floor and Input.is_action_just_pressed("jump"):

		var dir := -1 if right_col.is_colliding() else 1

		velocity.x = dir * actual_jump_x
		velocity.y = actual_jump_y

		is_walljumping = true
		timer = 0.0

		wall_jumped.emit()

	if is_walljumping:

		timer += delta

		if timer >= duration:
			is_walljumping = false

		if is_touching_wall() and timer > 0.1:
			is_walljumping = false

	return velocity


func is_touching_wall() -> bool:
	return right_col.is_colliding() or left_col.is_colliding()
