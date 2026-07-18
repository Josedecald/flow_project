extends Area2D
class_name Hitbox

@export var damage: int = 10
@onready var shape = $CollisionShape2D

func hitbox_on():
	shape.disabled = false

func hitbox_off():
	shape.disabled = true
