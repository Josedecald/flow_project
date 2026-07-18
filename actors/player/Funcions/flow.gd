extends Node
class_name FlowSystem

signal flow_changed(flow: float)
signal flow_boost(multiplier: float)

var flow: float = 0.0

func update_flow(delta: float, is_on_floor: bool, velocity_x: float, input_pressed: bool):
	aplicar_decay(delta, velocity_x)
	update_flow_moves(delta, is_on_floor, velocity_x, input_pressed)
	flow = clamp(flow, 0, 100)
	flow_changed.emit(flow)

func aplicar_decay(delta, velocity_x):
	if abs(velocity_x) < 20:
		flow -= 20 * delta
	else:
		flow -= 2 * delta

func update_flow_moves(delta, is_on_floor, velocity_x, input_pressed):
	if not is_on_floor:
		return
	if not input_pressed:
		return
	if abs(velocity_x) < 10:
		return
	flow += 5 * delta

func add_flow(value: float):
	flow += value
	flow_boost.emit()
