extends Node
class_name StateMachine

enum State {
	IDLE,
	WALK,
	RUN,
	SPRINT,
	JUMP,
	FALL,
	ON_WALL,
	DASH,
	SLIDE,
	WALL_JUMP,
	ATTACK
}

var current_state := State.IDLE

signal state_changed(previous, current)


func set_state(state: State):

	if current_state == state:
		return

	var previous = current_state
	current_state = state

	state_changed.emit(previous, current_state)


func is_state(state: State) -> bool:
	return current_state == state
