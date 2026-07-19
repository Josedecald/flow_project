extends CharacterBody2D
class_name Enemy

@onready var components: Node2D = $Components
@onready var health: Health = $Components/Health
@onready var hurtbox: Hurtbox = $Components/Hurtbox
@onready var flash: Flash = $Components/Flash
@onready var knockback: Knockback = $Components/Knockback
@onready var hitbox: Hitbox = $Components/Hitbox
@onready var playerdetector: Area2D = $Graphics/PlayerDetector
@onready var graphics: Node2D = $Graphics

var sprite_anim:AnimatedSprite2D

@export_group("Movement")

@export var move_speed: float = 45.0
@export var acceleration: float = 600.0
@export var friction: float = 900.0
var move_direction: float = 0.0
var facing_direction: int = 1

@export var attack_range: float
var player: CharacterBody2D

@export_group("Physics")

@export var gravity: float = ProjectSettings.get_setting(
	"physics/2d/default_gravity"
)

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HIT,
	DEAD
}
var current_state: State = State.IDLE
var previous_state: State = State.IDLE

@export var hit_duration: float = 0.15
var hit_timer: float = 0.0

var animations: Dictionary = {
}

func _physics_process(delta: float) -> void:
	
	update_state(delta)
	apply_gravity(delta)
	movement(delta)
	
	move_and_slide()
	
	update_direction()

func _ready():
	
	playerdetector.body_entered.connect(_on_player_detector_body_entered)
	playerdetector.body_exited.connect(_on_player_detector_body_exited)
	
	sprite_anim = flash.find_sprite(owner) as AnimatedSprite2D
	
	if sprite_anim == null:
		return 
	
	sprite_anim.frame_changed.connect(on_changed_frame)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)

	hitbox.hitbox_off()
	
func movement(delta: float):
	
	if knockback.is_active:
		velocity = knockback.current_force
		return
		
	var target_speed := move_direction * move_speed

	if move_direction != 0:
		velocity.x = move_toward(
			velocity.x,
			target_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			friction * delta
		)

func apply_gravity(delta: float):

	if not is_on_floor():
		velocity.y += gravity * delta

func update_direction() -> void:
	pass

func _on_health_changed(current_health: int, max_health: int):
	flash.flash()

	if current_state != State.DEAD:
		# Mantener la dirección actual al recibir daño
		var current_scale = graphics.scale.x
		change_state(State.HIT)
		graphics.scale.x = current_scale  # Restaurar escala después del cambio de estado

func _on_died():
	pass

signal state_changed(previous: State, current: State)

func change_state(new_state: State):
	if current_state == new_state:
		return

	# Guardar dirección actual antes del cambio
	var was_flipped = graphics.scale.x < 0

	if current_state == State.ATTACK:
		hitbox.hitbox_off()

	previous_state = current_state
	current_state = new_state

	state_changed.emit(previous_state, current_state)
	enter_state()

	# Restaurar dirección después de cambiar estados
	if was_flipped:
		graphics.scale.x = -abs(graphics.scale.x)
	else:
		graphics.scale.x = abs(graphics.scale.x)

func update_state(delta: float):

	match current_state:

		State.IDLE:
			state_idle(delta)

		State.PATROL:
			state_patrol(delta)

		State.CHASE:
			state_chase(delta)

		State.ATTACK:
			state_attack(delta)

		State.HIT:
			state_hit(delta)

		State.DEAD:
			state_dead(delta)

func update_animations():
	
	if not animations.has(current_state):
		return
	
	var actual_animation = animations[current_state]
	sprite_anim.play(actual_animation)
	
func state_idle(delta: float):
	pass


func state_patrol(delta: float):
	pass


func state_chase(delta: float):
	pass


func state_attack(delta: float):
	pass


func state_hit(delta: float):
	
	hit_timer -= delta
	
	if hit_timer <= 0.0:
		change_state(previous_state)


func state_dead(delta: float):
	pass
	
func enter_state():
	
	update_animations()
	
	match current_state:

		State.IDLE:
			enter_idle()

		State.PATROL:
			enter_patrol()

		State.CHASE:
			enter_chase()

		State.ATTACK:
			enter_attack()

		State.HIT:
			enter_hit()

		State.DEAD:
			enter_dead()
			
func enter_idle():
	pass

func enter_patrol():
	pass

func enter_chase():
	pass

func enter_attack():
	if animations.has(State.ATTACK):
		sprite_anim.play(animations[State.ATTACK])
		hitbox.hitbox_on()
		# Asegurar que hitbox tenga misma dirección que sprite
		hitbox.scale.x = graphics.scale.x

func enter_hit():
	hit_timer  = hit_duration
	
func enter_dead():
	pass

func on_player_detected():
	pass
	
func on_player_lost():
	pass

func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group('Player'):
		player = body
		on_player_detected()

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group('Player'):
		player = null
		on_player_lost()
		
func on_changed_frame():
	pass
