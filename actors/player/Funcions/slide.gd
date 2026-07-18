extends Node
class_name SlideSystem

signal slided

@export var slide_speed := 400.0
@export var slide_speed_max := 700.0
@export var duration := 0.30
@export var flow_required := 67.0

@onready var player: CharacterBody2D = $"../.."
@onready var collision: CollisionShape2D = $"../CollisionShape2D"
@onready var raycast: RayCast2D = $"../Graphics/RayCast2D"

var actual_speed := 0.0

var is_slide := false
var timer := 0.0


func update_stats(flow: float):
	actual_speed = lerp(
		slide_speed,
		slide_speed_max,
		flow / 100.0
	)


func update(
	velocity: Vector2,
	delta: float,
	flow: float,
	facing_right: bool,
	can_slide: bool
) -> Vector2:

	if can_slide \
	and !is_slide \
	and player.is_on_floor() \
	and flow >= flow_required \
	and Input.is_action_just_pressed("ui_slide"):

		start_slide()

		velocity.x = actual_speed if facing_right else -actual_speed

		slided.emit()

	if is_slide:

		timer += delta

		if timer >= duration and !raycast.is_colliding():
			stop_slide()

	return velocity


func start_slide():

	is_slide = true
	timer = 0.0

	collision.shape.size = Vector2(35,24)
	collision.position = Vector2(3.5,30)

	raycast.enabled = true


func stop_slide():

	is_slide = false

	collision.shape.size = Vector2(14,40)
	collision.position = Vector2(0,22)

	raycast.enabled = false
