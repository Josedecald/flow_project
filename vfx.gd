extends Node2D


func _on_animations_animation_finished() -> void:
	queue_free()
