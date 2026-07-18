extends Node
class_name VFXSystem

@onready var animations: AnimatedSprite2D = $"../../Graphics/animations"

func update(slide_active: bool):

	if slide_active:
		animations.visible = true
		animations.play("slide_vfx")
	else:
		animations.visible = false


func play_jump():

	# aquí instancias el efecto de salto
	pass
