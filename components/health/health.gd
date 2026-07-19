extends Node
class_name Health
signal health_changed(current_health: int, max_health: int)
signal died
@export var max_health: int = 100

var current_health: int

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)
	
func take_damage(damage_amount: int):
	current_health -= damage_amount
	current_health = clamp(current_health, 0, max_health)
	
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()

func heal(heal_amount: int):
	current_health += heal_amount
	current_health = clamp(current_health, 0, max_health)
	
	if current_health > 0:  # Solo emitir si no está muerto
		health_changed.emit(current_health, max_health)
	
func is_dead() -> bool:
	return current_health == 0
