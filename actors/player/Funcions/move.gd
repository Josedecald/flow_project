extends Node
class_name MovementSystem

@export var move_speed := 120.0
@export var move_speed_max := 260.0

@export var friction := 12.0
@export var friction_max := 20.0

@export var acceleration := 18.0
@export var acceleration_max := 32.0

@export var air_acceleration := 10.0
@export var air_acceleration_max := 18.0

@export var air_friction := 2.0
@export var air_friction_max := 5.0

@export var turn_acceleration := 24.0
@export var turn_acceleration_max := 40.0

var actual_speed: float
var actual_friction: float
var actual_acceleration: float
var actual_turn_acceleration: float


func update_stats(flow: float, on_floor: bool):

	if on_floor:
		actual_friction = lerp(friction, friction_max, flow / 100.0)
		actual_acceleration = lerp(acceleration, acceleration_max, flow / 100.0)
	else:
		actual_friction = lerp(air_friction, air_friction_max, flow / 100.0)
		actual_acceleration = lerp(air_acceleration, air_acceleration_max, flow / 100.0)

	actual_turn_acceleration = lerp(
		turn_acceleration,
		turn_acceleration_max,
		flow / 100.0
	)

	actual_speed = lerp(
		move_speed,
		move_speed_max,
		flow / 100.0
	)


func update(
	velocity_x: float,
	blocked: bool
) -> float:

	if blocked:
		return velocity_x

	var input := Input.get_axis("move_left", "move_rigth")

	var target := input * actual_speed

	if input == 0:
		return move_toward(
			velocity_x,
			target,
			actual_friction
		)

	if velocity_x * input > 0:
		return move_toward(
			velocity_x,
			target,
			actual_acceleration
		)

	return move_toward(
		velocity_x,
		target,
		actual_turn_acceleration
	)


func get_input_direction() -> float:
	return Input.get_axis("move_left", "move_rigth")
