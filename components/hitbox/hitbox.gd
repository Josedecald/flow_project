extends Area2D
class_name Hitbox

@export var damage: int = 10
@export var knockback_force: float = 300.0
@onready var shape = $CollisionShape2D

func hitbox_on():
	shape.disabled = false

func hitbox_off():
	shape.disabled = true
