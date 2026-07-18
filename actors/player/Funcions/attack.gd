extends Node
class_name AttackSystem

signal attack_started
signal attack_finished

@export var attack_cooldown := 0.30
@export var attack_active_time := 0.10

@onready var hitbox: Hitbox = $"../../Components/Hitbox"

var is_attacking := false

var cooldown_timer := 0.0
var active_timer := 0.0


func update(delta: float):

	if cooldown_timer > 0:
		cooldown_timer -= delta

	if !is_attacking \
	and cooldown_timer <= 0 \
	and Input.is_action_just_pressed("attack"):

		start_attack()

	if is_attacking:

		active_timer -= delta

		if active_timer <= 0:
			end_attack()


func start_attack():

	is_attacking = true

	cooldown_timer = attack_cooldown
	active_timer = attack_active_time

	hitbox.hitbox_on()

	attack_started.emit()


func end_attack():

	is_attacking = false

	hitbox.hitbox_off()

	attack_finished.emit()
