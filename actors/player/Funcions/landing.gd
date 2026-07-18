extends Node

@export var stretch := Vector2(1.08, 0.92)

@onready var player: CharacterBody2D = $"../.."
@onready var animated_sprite: AnimatedSprite2D = $"../../Graphics/AnimatedSprite"
@onready var camera = $"../../../Camera2D"

var freeze_active := false

var sprite_scale: Vector2
var target_sprite_scale: Vector2

var was_on_grounded := false
var last_y := 0.0


func _ready():
	sprite_scale = animated_sprite.scale
	target_sprite_scale = sprite_scale


func update():

	if !was_on_grounded and player.is_on_floor():

		if abs(last_y) < 700:
			camera.add_trauma(0.10)
			target_sprite_scale = Vector2(1.03,0.97)

		elif abs(last_y) < 1100:
			camera.add_trauma(0.20)
			target_sprite_scale = Vector2(1.12,0.88)
			start_freeze(0.025)

		else:
			camera.add_trauma(0.35)
			target_sprite_scale = Vector2(1.16,0.84)
			start_freeze(0.040)

	was_on_grounded = player.is_on_floor()

	animated_sprite.scale = animated_sprite.scale.lerp(target_sprite_scale,0.2)
	target_sprite_scale = target_sprite_scale.lerp(sprite_scale,0.15)

	last_y = player.velocity.y


func start_freeze(time:float):

	if freeze_active:
		return

	freeze_active = true

	Engine.time_scale = 0.10

	await get_tree().create_timer(time,true,false,true).timeout

	Engine.time_scale = 1.0
	freeze_active = false
