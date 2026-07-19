extends CharacterBody2D

# ============================================================
#  FLOW — el ritmo del jugador. Sube moviéndose, baja quieto.
# ============================================================
signal flow_changed(flow: float)
signal flow_boost(multiplier: float)

var flow: float = 0.0


# ============================================================
#  MOVIMIENTO
# ============================================================
@export_group("Movimiento")
@export var move_speed := 120.0
@export var move_speed_max := 260.0
@export var friction := 12.0
@export var friction_max := 20.0
@export var acceleration := 18.0
@export var acceleration_max := 32.0
@export var air_acceleration := 10.0
@export var air_acceleration_max := 18.0
@export var air_friction := 2.0
@export var air_friction_max := 5.0
@export var turn_acceleration := 24.0
@export var turn_acceleration_max := 40.0

var actual_speed: float
var actual_friction: float
var actual_acceleration: float
var actual_turn_acceleration: float


# ============================================================
#  SALTO
# ============================================================
@export_group("Salto")
signal jumped

@export var gravity := 980.0
@export var jump_speed := 250.0
@export var jump_speed_max := 400.0
@export var jump_release_multiplier := 2.0
@export var fall_gravity_multiplier := 2.5
@export var apex_velocity_threshold := 60.0
@export var apex_gravity_multiplier := 0.6
@export var jump_buffer_time := 0.12
@export var coyote_time := 0.10

var actual_jump := 0.0
var actual_gravity := 0.0
var jump_buffer := false
var jump_buffer_timer := 0.0
var was_on_floor := false
var coyote_timer := 0.0


# ============================================================
#  DASH
# ============================================================
@export_group("Dash")
signal dashed

@export var dash_speed := 400.0
@export var dash_speed_max := 700.0
@export var dash_duration := 0.30

var actual_dash := 0.0
var is_dashing := false
var dash_timer := 0.0


# ============================================================
#  SLIDE
# ============================================================
@export_group("Slide")
signal slided

@export var slide_speed := 400.0
@export var slide_speed_max := 700.0
@export var slide_duration := 0.30
@export var slide_flow_required := 67.0

var actual_slide_speed := 0.0
var is_slide := false
var slide_timer := 0.0


# ============================================================
#  WALL JUMP
# ============================================================
@export_group("Wall Jump")
signal wall_jumped

@export var wall_jump_x := 200.0
@export var wall_jump_x_max := 350.0
@export var wall_jump_y := -300.0
@export var wall_jump_y_max := -500.0
@export var wall_jump_duration := 0.5

var actual_wall_jump_x := 0.0
var actual_wall_jump_y := 0.0
var is_walljumping := false
var wall_jump_timer := 0.0


# ============================================================
#  ATAQUE
# ============================================================
@export_group("Ataque")
signal attack_started
signal attack_finished

@export var attack_cooldown := 0.30
@export var attack_active_time := 0.10

var is_attacking := false
var attack_cooldown_timer := 0.0
var attack_active_timer := 0.0


# ============================================================
#  ESTADO / ANIMACIÓN
# ============================================================
enum State {
	IDLE, WALK, RUN, SPRINT, JUMP, FALL, ON_WALL, DASH, SLIDE, WALL_JUMP, ATTACK
}

signal state_changed(previous, current)

var current_state := State.IDLE
var is_facing_right := true


# ============================================================
#  ATERRIZAJE (squash/stretch, camera trauma, freeze frame)
# ============================================================
var freeze_active := false
var sprite_scale: Vector2
var target_sprite_scale: Vector2
var was_on_grounded := false
var last_y := 0.0


# ============================================================
#  REFERENCIAS A NODOS DE LA ESCENA
# ============================================================
@onready var graphics: Node2D = $Graphics
@onready var animated_sprite: AnimatedSprite2D = $Graphics/AnimatedSprite
@onready var slide_vfx: AnimatedSprite2D = $Graphics/animations
@onready var wall_collision_right: RayCast2D = $wall_collision/right_col
@onready var wall_collision_left: RayCast2D = $wall_collision/left_col
@onready var slide_collision: CollisionShape2D = $CollisionShape2D
@onready var slide_raycast: RayCast2D = $Graphics/RayCast2D
@onready var hitbox: Hitbox = $Components/Hitbox
@onready var knockback: Knockback = $Components/Knockback
@onready var camera = $"../Camera2D"


func _ready() -> void:
	sprite_scale = animated_sprite.scale
	target_sprite_scale = sprite_scale


# ============================================================
#  LOOP PRINCIPAL — el orden acá importa, es la secuencia real
#  de un frame de física.
# ============================================================
func _physics_process(delta: float) -> void:

	update_flow(delta, is_on_floor(), velocity.x, get_input_direction() != 0)
	update_stats()

	velocity = update_dash(velocity, delta, !is_slide)
	velocity = update_slide(velocity, delta, !is_dashing)
	velocity = update_wall_jump(velocity, delta, is_on_floor())

	velocity.y = update_jump(velocity.y, delta, is_on_floor(), is_walljumping)

	velocity.x = update_move(
		velocity.x,
		is_dashing or is_slide or is_walljumping or knockback.is_active
	)

	if knockback.is_active:
		velocity = knockback.current_force

	update_state()

	move_and_slide()

	update_landing()
	update_slide_vfx()
	update_animation(get_input_direction())
	update_attack(delta)

	DebugOverlay.set_value("flow", roundf(flow))
	DebugOverlay.set_value("state", State.keys()[current_state])
	DebugOverlay.set_value("velocity", velocity)
	DebugOverlay.set_value("knockback_active", knockback.is_active)
	DebugOverlay.set_value("on_floor", is_on_floor())

	debug()
# ============================================================
#  FLOW
# ============================================================
func update_flow(delta: float, on_floor: bool, velocity_x: float, input_pressed: bool) -> void:
	_apply_flow_decay(delta, velocity_x)
	_apply_flow_gain(delta, on_floor, velocity_x, input_pressed)
	flow = clamp(flow, 0, 100)
	flow_changed.emit(flow)


func _apply_flow_decay(delta: float, velocity_x: float) -> void:
	if abs(velocity_x) < 20:
		flow -= 20 * delta
	else:
		flow -= 2 * delta


func _apply_flow_gain(delta: float, on_floor: bool, velocity_x: float, input_pressed: bool) -> void:
	if not on_floor:
		return
	if not input_pressed:
		return
	if abs(velocity_x) < 10:
		return
	flow += 5 * delta


func add_flow(value: float) -> void:
	flow += value
	flow_boost.emit()


## Recalcula, a partir del Flow actual, los valores "reales" que usa cada
## sistema (velocidad de dash real, salto real, etc). Se llama una vez
## por frame, siempre después de update_flow().
func update_stats() -> void:

	if is_on_floor():
		actual_friction = lerp(friction, friction_max, flow / 100.0)
		actual_acceleration = lerp(acceleration, acceleration_max, flow / 100.0)
	else:
		actual_friction = lerp(air_friction, air_friction_max, flow / 100.0)
		actual_acceleration = lerp(air_acceleration, air_acceleration_max, flow / 100.0)

	actual_turn_acceleration = lerp(turn_acceleration, turn_acceleration_max, flow / 100.0)
	actual_speed = lerp(move_speed, move_speed_max, flow / 100.0)

	actual_jump = lerp(jump_speed, jump_speed_max, flow / 100.0)

	actual_dash = lerp(dash_speed, dash_speed_max, flow / 100.0)

	actual_slide_speed = lerp(slide_speed, slide_speed_max, flow / 100.0)

	actual_wall_jump_x = lerp(wall_jump_x, wall_jump_x_max, flow / 100.0)
	actual_wall_jump_y = lerp(wall_jump_y, wall_jump_y_max, flow / 100.0)


# ============================================================
#  MOVIMIENTO
# ============================================================
func get_input_direction() -> float:
	return Input.get_axis("move_left", "move_rigth")


func update_move(velocity_x: float, blocked: bool) -> float:

	if blocked:
		return velocity_x

	var input := get_input_direction()
	var target := input * actual_speed

	if input == 0:
		return move_toward(velocity_x, target, actual_friction)

	if velocity_x * input > 0:
		return move_toward(velocity_x, target, actual_acceleration)

	return move_toward(velocity_x, target, actual_turn_acceleration)


# ============================================================
#  SALTO
# ============================================================
func update_jump(velocity_y: float, delta: float, on_floor: bool, blocked: bool) -> float:

	if blocked:
		return velocity_y

	if Input.is_action_just_pressed("jump"):
		jump_buffer = true
		jump_buffer_timer = 0.0

	_update_jump_buffer(delta)
	_update_coyote(delta, on_floor)

	actual_gravity = _calculate_gravity(velocity_y)

	if !on_floor:
		velocity_y += actual_gravity * delta

	if jump_buffer and (on_floor or was_on_floor):
		jump_buffer = false
		was_on_floor = false
		jumped.emit()
		return -actual_jump

	return velocity_y


func _update_jump_buffer(delta: float) -> void:
	if !jump_buffer:
		return
	jump_buffer_timer += delta
	if jump_buffer_timer >= jump_buffer_time:
		jump_buffer = false
		jump_buffer_timer = 0.0


func _update_coyote(delta: float, on_floor: bool) -> void:
	if on_floor:
		was_on_floor = true
		coyote_timer = 0.0
		return
	if was_on_floor:
		coyote_timer += delta
		if coyote_timer >= coyote_time:
			was_on_floor = false


func _calculate_gravity(velocity_y: float) -> float:
	if velocity_y < 0:
		if abs(velocity_y) <= apex_velocity_threshold:
			return gravity * apex_gravity_multiplier
		if Input.is_action_pressed("jump"):
			return gravity
		return gravity * jump_release_multiplier
	if velocity_y > 0:
		return gravity * fall_gravity_multiplier
	return gravity


# ============================================================
#  DASH
# ============================================================
func update_dash(velocity: Vector2, delta: float, can_dash: bool) -> Vector2:

	if can_dash and !is_dashing and Input.is_action_just_pressed("ui_dash"):
		is_dashing = true
		dash_timer = 0.0
		velocity.x = actual_dash if is_facing_right else -actual_dash
		dashed.emit()

	if is_dashing:
		dash_timer += delta
		if dash_timer >= dash_duration:
			is_dashing = false

	return velocity


# ============================================================
#  SLIDE
# ============================================================
func update_slide(velocity: Vector2, delta: float, can_slide: bool) -> Vector2:

	if can_slide \
	and !is_slide \
	and is_on_floor() \
	and flow >= slide_flow_required \
	and Input.is_action_just_pressed("ui_slide"):

		_start_slide()
		velocity.x = actual_slide_speed if is_facing_right else -actual_slide_speed
		slided.emit()

	if is_slide:
		slide_timer += delta
		if slide_timer >= slide_duration and !slide_raycast.is_colliding():
			_stop_slide()

	return velocity


func _start_slide() -> void:
	is_slide = true
	slide_timer = 0.0
	slide_collision.shape.size = Vector2(35, 24)
	slide_collision.position = Vector2(3.5, 30)
	slide_raycast.enabled = true


func _stop_slide() -> void:
	is_slide = false
	slide_collision.shape.size = Vector2(14, 40)
	slide_collision.position = Vector2(0, 22)
	slide_raycast.enabled = false


# ============================================================
#  WALL JUMP
# ============================================================
func update_wall_jump(velocity: Vector2, delta: float, on_floor: bool) -> Vector2:

	if is_touching_wall() and !on_floor:
		velocity.y = min(velocity.y, 30)

	if is_touching_wall() and !on_floor and Input.is_action_just_pressed("jump"):

		var dir := -1 if wall_collision_right.is_colliding() else 1

		velocity.x = dir * actual_wall_jump_x
		velocity.y = actual_wall_jump_y

		is_facing_right = dir > 0
		graphics.scale.x = abs(graphics.scale.x) * dir

		is_walljumping = true
		wall_jump_timer = 0.0

		wall_jumped.emit()

	if is_walljumping:
		wall_jump_timer += delta
		if wall_jump_timer >= wall_jump_duration:
			is_walljumping = false
		if is_touching_wall() and wall_jump_timer > 0.1:
			is_walljumping = false

	return velocity


func is_touching_wall() -> bool:
	return wall_collision_right.is_colliding() or wall_collision_left.is_colliding()


# ============================================================
#  ATAQUE
# ============================================================
func update_attack(delta: float) -> void:

	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta

	if !is_attacking \
	and attack_cooldown_timer <= 0 \
	and Input.is_action_pressed("attack"):
		_start_attack()

	if is_attacking:
		attack_active_timer -= delta
		if attack_active_timer <= 0:
			_end_attack()


func _start_attack() -> void:
	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	attack_active_timer = attack_active_time
	hitbox.hitbox_on()
	attack_started.emit()


func _end_attack() -> void:
	is_attacking = false
	hitbox.hitbox_off()
	attack_finished.emit()


# ============================================================
#  ESTADO (decide qué animación corresponde este frame)
# ============================================================
func update_state() -> void:

	if is_dashing:
		_set_state(State.DASH)

	elif is_slide:
		_set_state(State.SLIDE)

	elif is_walljumping:
		_set_state(State.WALL_JUMP)

	elif is_attacking:
		_set_state(State.ATTACK)

	elif !is_on_floor():

		if is_touching_wall():
			_set_state(State.ON_WALL)
		elif velocity.y < 0:
			_set_state(State.JUMP)
		else:
			_set_state(State.FALL)

	elif abs(velocity.x) < 10:
		_set_state(State.IDLE)

	elif flow < 33:
		_set_state(State.WALK)

	elif flow < 66:
		_set_state(State.RUN)

	else:
		_set_state(State.SPRINT)


func _set_state(state: State) -> void:
	if current_state == state:
		return
	var previous = current_state
	current_state = state
	state_changed.emit(previous, current_state)


func is_state(state: State) -> bool:
	return current_state == state


# ============================================================
#  ANIMACIÓN (reproduce el sprite correcto para el estado actual)
# ============================================================
func update_animation(input_dir: float) -> void:

	_update_flip(input_dir)

	match current_state:
		State.IDLE: animated_sprite.play("idle")
		State.WALK: animated_sprite.play("walk")
		State.RUN: animated_sprite.play("run")
		State.SPRINT: animated_sprite.play("sprint")
		State.JUMP: animated_sprite.play("jump")
		State.FALL: animated_sprite.play("fall")
		State.ON_WALL: animated_sprite.play("wall_land")
		State.DASH: animated_sprite.play("dash")
		State.SLIDE: animated_sprite.play("slide")
		State.WALL_JUMP: animated_sprite.play("jump")
		State.ATTACK: animated_sprite.play("attack")

	_update_animation_speed()


func _update_animation_speed() -> void:

	if actual_speed <= 0:
		animated_sprite.speed_scale = 1.0
		return

	match animated_sprite.animation:
		"idle", "walk", "run", "sprint":
			var p = clamp(abs(velocity.x) / actual_speed, 0.0, 1.0)
			animated_sprite.speed_scale = lerp(0.8, 1.6, p)
		_:
			animated_sprite.speed_scale = 1.0


## El sprite solo voltea según hacia dónde apretás — nunca por knockback,
## dash, ni rebotes contra una pared.
func _update_flip(input_dir: float) -> void:

	if input_dir == 0:
		return

	var facing := input_dir > 0

	if facing != is_facing_right:
		is_facing_right = facing
		graphics.scale.x *= -1


# ============================================================
#  FEEDBACK DE ATERRIZAJE (squash/stretch, camera trauma)
# ============================================================
func update_landing() -> void:

	if !was_on_grounded and is_on_floor():

		if abs(last_y) < 700:
			camera.add_trauma(0.10)
			target_sprite_scale = Vector2(1.03, 0.97)

		elif abs(last_y) < 1100:
			camera.add_trauma(0.20)
			target_sprite_scale = Vector2(1.12, 0.88)
			_start_freeze(0.025)

		else:
			camera.add_trauma(0.35)
			target_sprite_scale = Vector2(1.16, 0.84)
			_start_freeze(0.040)

	was_on_grounded = is_on_floor()

	animated_sprite.scale = animated_sprite.scale.lerp(target_sprite_scale, 0.2)
	target_sprite_scale = target_sprite_scale.lerp(sprite_scale, 0.15)

	last_y = velocity.y


func _start_freeze(time: float) -> void:

	if freeze_active:
		return

	freeze_active = true
	Engine.time_scale = 0.10

	await get_tree().create_timer(time, true, false, true).timeout

	Engine.time_scale = 1.0
	freeze_active = false


# ============================================================
#  VFX de slide — el resto de efectos (salto, wall jump, etc.)
#  quedan pendientes para la Fase 8 del roadmap (Arte/Audio).
# ============================================================
func update_slide_vfx() -> void:
	if is_slide:
		slide_vfx.visible = true
		slide_vfx.play("slide_vfx")
	else:
		slide_vfx.visible = false
		
func debug():
	if OS.is_debug_build() and Input.is_physical_key_pressed(KEY_PAGEDOWN):
		flow = 100.0
