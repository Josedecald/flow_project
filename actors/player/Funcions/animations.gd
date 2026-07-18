extends Node
class_name AnimationSystem

@onready var player: CharacterBody2D = $"../.."
@onready var graphics: Node2D = $"../../Graphics"
@onready var animated_sprite: AnimatedSprite2D = $"../../Graphics/AnimatedSprite"

var is_facing_right := true


func update(state: StateMachine.State, actual_speed: float):

	update_flip()

	match state:

		StateMachine.State.IDLE:
			animated_sprite.play("idle")

		StateMachine.State.WALK:
			animated_sprite.play("walk")

		StateMachine.State.RUN:
			animated_sprite.play("run")

		StateMachine.State.SPRINT:
			animated_sprite.play("sprint")

		StateMachine.State.JUMP:
			animated_sprite.play("jump")

		StateMachine.State.FALL:
			animated_sprite.play("fall")

		StateMachine.State.ON_WALL:
			animated_sprite.play("wall_land")

		StateMachine.State.DASH:
			animated_sprite.play("dash")

		StateMachine.State.SLIDE:
			animated_sprite.play("slide")

		StateMachine.State.WALL_JUMP:
			animated_sprite.play("jump")

		StateMachine.State.ATTACK:
			animated_sprite.play("attack")

	update_speed(actual_speed)


func update_speed(actual_speed: float):

	if actual_speed <= 0:
		animated_sprite.speed_scale = 1.0
		return

	match animated_sprite.animation:

		"idle", "walk", "run", "sprint":
			var p = clamp(abs(player.velocity.x) / actual_speed, 0.0, 1.0)
			animated_sprite.speed_scale = lerp(0.8, 1.6, p)

		_:
			animated_sprite.speed_scale = 1.0


func update_flip():

	if player.velocity.x == 0:
		return

	var facing := player.velocity.x > 0

	if facing != is_facing_right:
		is_facing_right = facing
		graphics.scale.x *= -1
