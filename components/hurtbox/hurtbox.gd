extends Area2D
class_name Hurtbox

signal hit(hitbox)

@export var invulnerability_time: float = 0.15
var invulnerable: bool = false
var invulnerability_timer: float = 0.0

func _process(delta: float) -> void:
	if not invulnerable:
		return
	invulnerability_timer -= delta
	if invulnerability_timer <= 0:
		invulnerable = false
		invulnerability_timer = 0

func _on_area_entered(area: Area2D) -> void:
	if not area is Hitbox:
		return
	if invulnerable:
		return
	invulnerable = true
	invulnerability_timer = invulnerability_time
	hit.emit(area)
