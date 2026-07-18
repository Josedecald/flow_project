extends Node
class_name JumpSystem

signal jumped

@export var gravity := 980.0

@export var jump_speed := 250.0
@export var jump_speed_max := 400.0

@export var jump_release_multiplier := 2.0
@export var fall_gravity_multiplier := 2.5
@export var apex_velocity_threshold := 60.0
@export var apex_gravity_multiplier := 0.6

@export var jump_buffer_time := 0.12
@export var coyote_time := 0.10

var actual_jump := 0.0
var actual_gravity := 0.0

var jump_buffer := false
var jump_buffer_timer := 0.0

var was_on_floor := false
var coyote_timer := 0.0


func update_stats(flow: float):
	actual_jump = lerp(jump_speed, jump_speed_max, flow / 100.0)


func update(
	velocity_y: float,
	delta: float,
	on_floor: bool,
	blocked: bool
) -> float:

	if blocked:
		return velocity_y

	if Input.is_action_just_pressed("jump"):
		jump_buffer = true
		jump_buffer_timer = 0.0

	update_jump_buffer(delta)
	update_coyote(delta, on_floor)

	actual_gravity = calculate_gravity(velocity_y)

	if !on_floor:
		velocity_y += actual_gravity * delta

	if jump_buffer and (on_floor or was_on_floor):
		jump_buffer = false
		was_on_floor = false
		jumped.emit()
		return -actual_jump

	return velocity_y


func update_jump_buffer(delta):

	if !jump_buffer:
		return

	jump_buffer_timer += delta

	if jump_buffer_timer >= jump_buffer_time:
		jump_buffer = false
		jump_buffer_timer = 0.0


func update_coyote(delta, on_floor):

	if on_floor:
		was_on_floor = true
		coyote_timer = 0.0
		return

	if was_on_floor:
		coyote_timer += delta

		if coyote_timer >= coyote_time:
			was_on_floor = false


func calculate_gravity(velocity_y: float) -> float:

	if velocity_y < 0:

		if abs(velocity_y) <= apex_velocity_threshold:
			return gravity * apex_gravity_multiplier

		if Input.is_action_pressed("jump"):
			return gravity

		return gravity * jump_release_multiplier

	if velocity_y > 0:
		return gravity * fall_gravity_multiplier

	return gravity
