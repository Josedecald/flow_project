extends Node2D

@onready var health: Health = $Dummy/Health

func _ready() -> void:
	
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	
func _on_health_changed(current, max):
	print("Vida:", current, "/", max)

func _on_died():
	print("Dummy muerto")
