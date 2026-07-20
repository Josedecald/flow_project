extends Enemy
class_name Walker

@export_group("Patrol")

@export var start_direction: int = 1

@onready var ground_ray: RayCast2D = $Graphics/GroundRay
@onready var wall_ray: RayCast2D = $Graphics/WallRay
@onready var camera = $"../Camera2D"
@onready var attack_range_area: Area2D = $Graphics/AttackRange

var player_in_attack_range: bool = false

func _process(delta: float) -> void:
	print(current_state)

func _ready() -> void:

	super()
	animations = {
	State.IDLE: 'idle',
	State.PATROL: 'walk',
	State.CHASE: 'walk',
	State.ATTACK: 'attack',
	State.HIT: 'hurt',
	State.DEAD: 'die'
	}
	set_direction(start_direction)
	change_state(State.PATROL)
	attack_range_area.body_entered.connect(_on_attack_range_body_entered)
	attack_range_area.body_exited.connect(_on_attack_range_body_exited)

func enter_patrol():
	pass

func enter_chase():
	pass

func update_direction() -> void:

	graphics.scale.x = facing_direction
	components.scale.x = facing_direction

func check_chase():
	if player == null:
		return
	
	if player_in_attack_range:
		return
	
	if global_position.x > player.global_position.x:
		set_direction(-1)
	else:
		set_direction(1)
	
func _on_attack_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_attack_range = true
		if current_state != State.DEAD and current_state != State.HIT:
			change_state(State.ATTACK)

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		player_in_attack_range = false
		if current_state != State.DEAD and current_state != State.HIT:
			change_state(State.CHASE)
	
func check_patrol():

	if not ground_ray.is_colliding():
		turn_around()
		return

	if wall_ray.is_colliding():
		turn_around()
		
func turn_around() -> void:

	set_direction(-facing_direction)

func set_direction(direction: int) -> void:

	move_direction = direction
	facing_direction = direction

func state_attack(delta):
	pass

func state_patrol(delta):
	check_patrol()

func state_chase(delta):
	check_chase()

func on_player_detected():
	change_state(State.CHASE)

func on_player_lost():
	change_state(State.PATROL)

func _on_animated_sprite_2d_animation_finished(anim_name):

	if anim_name != animations[State.ATTACK]:
		return

	if player == null:
		change_state(State.PATROL)
		return

	if player_in_attack_range:
		change_state(State.ATTACK)
	else:
		change_state(State.CHASE)
			
func on_changed_frame():
	if sprite_anim.animation != animations[State.ATTACK]:
		return
	
	if sprite_anim.frame in [7,8,9]:
		camera.add_trauma(0.8)
		hitbox.hitbox_on()
	else:
		hitbox.hitbox_off()
			

		
	
