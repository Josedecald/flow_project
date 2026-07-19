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
@export var jump_speed := 300.0
@export var jump_speed_max := 500.0
@export var jump_release_multiplier := 2.0
@export var fall_gravity_multiplier := 2.0  # Gravedad más consistente
@export var apex_velocity_threshold := 80.0  # Mayor margen para el apex
@export var apex_gravity_multiplier := 0.9 # Flotación balanceada
@export var jump_buffer_time := 0.12
@export var coyote_time := 0.10
@export var jump_cut_multiplier := 0.6  # Menos brusco al soltar

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

@export var slide_speed := 500.0  # Velocidad fija
@export var slide_duration := 0.30
@export var slide_flow_required := 40.0  # Requisito mínimo de flow
@export var dash_flow_cost := 30.0
@export var attack_flow_cost := 30.0

# Slide usa velocidad fija
var is_slide := false
var slide_timer := 0.0

# ============================================================
#  HURT / DEATH
# ============================================================
var hurt_timer: float = 0.0
var invulnerability_time: float = 1.0  # 1 segundo de invulnerabilidad
@export var hit_flash_duration: float = 0.1
@export var hit_flash_count: int = 3
var previous_state_before_hurt: State = State.IDLE
# ============================================================
#  WALL JUMP
# ============================================================
@export_group("Wall Jump")
signal wall_jumped

@export var wall_jump_x := 400.0  # Valor fijo horizontal
@export var wall_jump_y := -350.0  # Valor fijo vertical 
@export var wall_jump_duration := 0.25  # Tiempo fijo
@export var wall_jump_control_multiplier := 0.6  # Control aéreo
@export var wall_slide_speed := 120.0  # Velocidad fija
@export var wall_slide_accel := 500.0  # Aceleración fija
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
	IDLE, WALK, RUN, SPRINT, JUMP, FALL, ON_WALL, DASH, SLIDE, WALL_JUMP, ATTACK, HURT, DEAD
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
@onready var health: Health = $Components/Health
@onready var hurtbox: Hurtbox = $Components/Hurtbox
@onready var flash: Flash = $Components/Flash
@onready var health_bar: ProgressBar = $HealthBar  # Asegúrate que el nodo tiene este nombre


func _ready() -> void:
	sprite_scale = animated_sprite.scale
	target_sprite_scale = sprite_scale
	health.died.connect(_on_died)
	hurtbox.hit.connect(_on_hit)
	health.health_changed.connect(_update_health_bar)

	# Conectar fin de animación para muerte
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	# Inicializar barra de salud
	if health_bar:
		health_bar.max_value = health.max_health
		health_bar.value = health.current_health


# ============================================================
#  LOOP PRINCIPAL — el orden acá importa, es la secuencia real
#  de un frame de física.
# ============================================================
func _physics_process(delta: float) -> void:

	update_flow(delta, is_on_floor(), velocity.x, get_input_direction() != 0)
	update_stats()
	
	if current_state != State.HURT and current_state != State.DEAD:
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
	
	if current_state == State.HURT:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and not health.is_dead():
			# Volver al estado anterior (el que teníamos antes de ser golpeados)
			change_state(previous_state_before_hurt)
	
	update_landing()
	update_slide_vfx()
	update_animation(get_input_direction())
	update_attack(delta)

	DebugOverlay.set_value("flow", roundf(flow))
	DebugOverlay.set_value("state", State.keys()[current_state])
	DebugOverlay.set_value("velocity", velocity)
	DebugOverlay.set_value("knockback_active", knockback.is_active)
	DebugOverlay.set_value("on_floor", is_on_floor())
	DebugOverlay.set_value('Gravity', gravity)

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
	# Solo decae naturalmente cuando no estás moviéndote
	if abs(velocity_x) < 20:
		flow = move_toward(flow, 0, 10 * delta)


func _apply_flow_gain(delta: float, on_floor: bool, velocity_x: float, input_pressed: bool) -> void:
	# Solo ganas flow cuando corres y estás en el suelo
	if not on_floor or not input_pressed:
		return
	if abs(velocity_x) > 100:
		flow = move_toward(flow, 100, 15 * delta)


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

	# Slide usa velocidad fija

	# Walljump usa valores fijos, no depende del flow


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
	if velocity_y < 0:  # Subiendo
		if abs(velocity_y) <= apex_velocity_threshold:
			return gravity * apex_gravity_multiplier
		if !Input.is_action_pressed("jump"):
			return gravity * jump_cut_multiplier
		return gravity  # Gravedad consistentemente reducida
	elif velocity_y > 0:  # Bajando
		return gravity * fall_gravity_multiplier
	return gravity


# ============================================================
#  DASH
# ============================================================
func update_dash(velocity: Vector2, delta: float, can_dash: bool) -> Vector2:

	if can_dash and !is_dashing and Input.is_action_just_pressed("ui_dash") and flow >= dash_flow_cost:
		is_dashing = true
		dash_timer = 0.0
		velocity.x = actual_dash if is_facing_right else -actual_dash
		flow -= dash_flow_cost
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
		velocity.x = slide_speed if is_facing_right else -slide_speed
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
	# Wall Slide - deslizar por la pared
	if is_touching_wall() and !on_floor:
		velocity.y = min(velocity.y, wall_slide_speed)
		velocity.y = move_toward(velocity.y, wall_slide_speed, wall_slide_accel * delta)

	# Wall Jump
	if is_touching_wall() and !on_floor and Input.is_action_just_pressed("jump"):
		var dir := -1 if wall_collision_right.is_colliding() else 1
		
		# Aplicar fuerza inicial
		velocity.x = dir * wall_jump_x
		velocity.y = wall_jump_y
		
		is_facing_right = dir > 0
		graphics.scale.x = abs(graphics.scale.x) * dir
		_set_state(State.WALL_JUMP, true)
		
		is_walljumping = true
		wall_jump_timer = 0.0
		wall_jumped.emit()

	# Impulso durante walljump
	if is_walljumping:
		wall_jump_timer += delta
		var input_dir := get_input_direction()
		
		# Aplicar gravedad reducida solo al inicio
		if wall_jump_timer < wall_jump_duration * 0.5:
			velocity.y += gravity * 0.5 * delta
		else:
			velocity.y += gravity * delta
		
		# Permitir control mínimo
		if input_dir != 0:
			var control_dir := input_dir * wall_jump_x * wall_jump_control_multiplier
			velocity.x = move_toward(velocity.x, control_dir, actual_acceleration * 2 * delta)
		
		# Finalizar walljump
		if wall_jump_timer >= wall_jump_duration:
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
	and Input.is_action_pressed("attack") \
	and flow >= attack_flow_cost:
		flow -= attack_flow_cost
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
	 
	if health.is_dead():
		_set_state(State.DEAD)
		return
		
	if current_state == State.HURT:
		return

	if is_attacking:
		_set_state(State.ATTACK)
		return
	
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


func _set_state(state: State, force: bool = false) -> void:
	if current_state == state and not force:
		return
	var previous = current_state
	current_state = state
	state_changed.emit(previous, current_state)
	enter_state()

func enter_state() -> void:
	match current_state:
		State.IDLE:      enter_idle()
		State.WALK:      enter_walk()
		State.RUN:       enter_run()
		State.SPRINT:    enter_sprint()
		State.JUMP:      enter_jump()
		State.FALL:      enter_fall()
		State.ON_WALL:   enter_on_wall()
		State.DASH:      enter_dash()
		State.SLIDE:     enter_slide()
		State.WALL_JUMP: enter_wall_jump()
		State.ATTACK:    enter_attack()
		State.HURT:      enter_hurt()
		State.DEAD:      enter_dead()
		
func enter_idle():      pass
func enter_walk():      pass
func enter_run():       pass
func enter_sprint():    pass
func enter_jump():      pass
func enter_fall():      pass
func enter_on_wall():   pass
func enter_dash():      pass
func enter_slide():     pass
func enter_wall_jump(): pass
func enter_attack():    pass

func is_state(state: State) -> bool:
	return current_state == state

func enter_hurt() -> void:
	hurt_timer = invulnerability_time
	# Opcional: puedes detener el movimiento bruscamente
	# velocity = Vector2.ZERO
	
func enter_dead() -> void:
	# Desactivar colisiones y componentes
	set_physics_process(false)  # opcional, o simplemente detener movimiento
	hitbox.hitbox_off()
	# También podrías desactivar el hurtbox para que no reciba más daño
	hurtbox.monitoring = false
	hurtbox.monitorable = false
	# La animación "die" se reproducirá, y al terminar reiniciaremos la escena

func change_state(new_state: State) -> void:
	if current_state == new_state:
		return

	# Si estamos saliendo de ATTACK, apagar hitbox
	if current_state == State.ATTACK:
		hitbox.hitbox_off()

	# Guardar el estado anterior ANTES de cambiar (para volver después de HURT)
	if new_state == State.HURT:
		previous_state_before_hurt = current_state

	# Ejecutar el cambio
	var previous = current_state
	current_state = new_state
	state_changed.emit(previous, current_state)
	enter_state()
	
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
		State.HURT: animated_sprite.play("hurt")
		State.DEAD: animated_sprite.play("die")

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
## dash, walljump ni rebotes contra una pared.
func _update_flip(input_dir: float) -> void:
	if current_state in [State.HURT, State.DEAD, State.WALL_JUMP]:
		return
		
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

func _on_hit(hitbox: Hitbox) -> void:
	if _can_take_damage():
		_apply_damage_effects(hitbox)
		change_state(State.HURT)
		_start_invulnerability()

func _can_take_damage() -> bool:
	return not health.is_dead() and current_state != State.HURT

func _apply_damage_effects(hitbox: Hitbox) -> void:
	health.take_damage(hitbox.damage)
	flash.start_flash()
	_apply_knockback(hitbox)
	flow = max(flow - 30, 0)

func _apply_knockback(hitbox: Hitbox) -> void:
	var direction = (global_position - hitbox.global_position).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT if is_facing_right else Vector2.LEFT
	knockback.apply(direction, hitbox.knockback_force)

func _start_invulnerability() -> void:
	hurtbox.set_deferred("monitoring", false)
	await get_tree().create_timer(invulnerability_time).timeout
	hurtbox.monitoring = true


func _on_died() -> void:
	change_state(State.DEAD)

func debug():
	if OS.is_debug_build() and Input.is_physical_key_pressed(KEY_PAGEDOWN):
		flow = 100.0

func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = health.current_health


func _on_animation_finished() -> void:
	if animated_sprite.animation == "die":
			# Reiniciar la escena (o mostrar pantalla de game over)
			get_tree().reload_current_scene()
