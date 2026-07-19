extends Node

@onready var sprite: AnimatedSprite2D = get_parent()
@export var hit_flash_duration: float = 0.1
@export var hit_flash_count: int = 3

func start_flash():
	for i in range(hit_flash_count):
		sprite.modulate.a = 0.5
		await get_tree().create_timer(hit_flash_duration, false).timeout
		sprite.modulate.a = 1.0
		await get_tree().create_timer(hit_flash_duration, false).timeout
