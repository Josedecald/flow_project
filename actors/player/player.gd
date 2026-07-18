extends CharacterBody2D

@onready var flow_system: FlowSystem = $funcions/flow
@onready var movement: MovementSystem = $funcions/Move
@onready var jump_system: JumpSystem = $funcions/jump
@onready var dash_system: DashSystem = $funcions/dash
@onready var slide_system: SlideSystem = $funcions/slide
@onready var wall_jump_system: WallJumpSystem = $funcions/wall_jump
@onready var attack_system: AttackSystem = $funcions/attack
@onready var landing_system = $funcions/landing
@onready var vfx_system = $funcions/vfx
@onready var animation_system: AnimationSystem = $funcions/animations
@onready var state_machine: StateMachine = $funcions/state_machine
@onready var knockback: Knockback = $Components/Knockback

func _ready():
	jump_system.jumped.connect(vfx_system.play_jump)

func _physics_process(delta):

	flow_system.update_flow(
		delta,
		is_on_floor(),
		velocity.x,
		Input.get_axis("move_left","move_rigth") != 0
	)

	movement.update_stats(flow_system.flow, is_on_floor())
	jump_system.update_stats(flow_system.flow)
	dash_system.update_stats(flow_system.flow)
	slide_system.update_stats(flow_system.flow)
	wall_jump_system.update_stats(flow_system.flow)

	velocity = dash_system.update(
		velocity,
		delta,
		animation_system.is_facing_right,
		!slide_system.is_slide
	)
	velocity = slide_system.update(
		velocity,
		delta,
		flow_system.flow,
		animation_system.is_facing_right,
		!dash_system.is_dashing
	)
	velocity = wall_jump_system.update(
		velocity,
		delta,
		is_on_floor()
	)

	velocity.y = jump_system.update(
	velocity.y,
	delta,
	is_on_floor(),
	wall_jump_system.is_walljumping
	)

	velocity.x = movement.update(
		velocity.x,
		dash_system.is_dashing
		or slide_system.is_slide
		or wall_jump_system.is_walljumping
		or knockback.is_active
	)

	if knockback.is_active:
		velocity = knockback.current_force

	
	if dash_system.is_dashing:
		state_machine.set_state(StateMachine.State.DASH)

	elif slide_system.is_slide:
		state_machine.set_state(StateMachine.State.SLIDE)

	elif wall_jump_system.is_walljumping:
		state_machine.set_state(StateMachine.State.WALL_JUMP)

	elif attack_system.is_attacking:
		state_machine.set_state(StateMachine.State.ATTACK)

	elif !is_on_floor():

		if wall_jump_system.is_touching_wall():
			state_machine.set_state(StateMachine.State.ON_WALL)

		elif velocity.y < 0:
			state_machine.set_state(StateMachine.State.JUMP)

		else:
			state_machine.set_state(StateMachine.State.FALL)

	elif abs(velocity.x) < 10:
		state_machine.set_state(StateMachine.State.IDLE)

	elif flow_system.flow < 33:
		state_machine.set_state(StateMachine.State.WALK)

	elif flow_system.flow < 66:
		state_machine.set_state(StateMachine.State.RUN)

	else:
		state_machine.set_state(StateMachine.State.SPRINT)

	move_and_slide()

	landing_system.update()

	vfx_system.update(slide_system.is_slide)

	animation_system.update(
		state_machine.current_state,
		movement.actual_speed,
		Input.get_axis("move_left", "move_rigth")
	)
	
	attack_system.update(delta)
