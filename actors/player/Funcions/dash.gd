extends Node
class_name DashSystem

signal dashed

@export var dash_speed := 400.0
@export var dash_speed_max := 700.0
@export var dash_duration := 0.30

var actual_dash := 0.0

var is_dashing := false
var timer := 0.0


func update_stats(flow: float):
	actual_dash = lerp(
		dash_speed,
		dash_speed_max,
		flow / 100.0
	)


func update(
	velocity: Vector2,
	delta: float,
	facing_right: bool,
	can_dash: bool
) -> Vector2:

	if can_dash \
	and !is_dashing \
	and Input.is_action_just_pressed("ui_dash"):

		is_dashing = true
		timer = 0.0

		velocity.x = actual_dash if facing_right else -actual_dash

		dashed.emit()

	if is_dashing:

		timer += delta

		if timer >= dash_duration:
			is_dashing = false

	return velocity
