extends CanvasLayer

@onready var progressBar = $"flow bar"


func _ready() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player:
		player.flow_changed.connect(_on_player_flow_changed)


func _on_player_flow_changed(flow: float) -> void:
	progressBar.value = flow
