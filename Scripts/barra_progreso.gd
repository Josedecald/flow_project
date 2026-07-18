extends CanvasLayer

@onready var progressBar = $"flow bar"

func _on_player_flow_changed(flow: float) -> void:
	progressBar.value = flow
