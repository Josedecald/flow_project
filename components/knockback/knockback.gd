extends Node
class_name Knockback

@export var decay: float = 1800.0

var current_force: Vector2 = Vector2.ZERO
var is_active: bool = false

func _physics_process(delta):
	
	if not is_active:
		return

	current_force = current_force.move_toward(Vector2.ZERO, decay * delta)

	if current_force.is_zero_approx():
		current_force = Vector2.ZERO
		is_active = false
	

func apply(direction: Vector2, force: float):
	pass
