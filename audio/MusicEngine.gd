# music/MusicEngine.gd
extends Node

# Referencias a las capas (pueden estar vacías al inicio)
var ambient_layer
var melody_layer
var effect_layer

func _ready():
	# Cargar capas de forma segura
	var AmbientLayer = load("res://audio/layers/AmbientLayer.gd")
	var MelodyLayer = load("res://audio/layers/MelodyLayer.gd")
	var EffectLayer = load("res://audio/layers/EffectLayer.gd")
	
	if AmbientLayer:
		ambient_layer = AmbientLayer.new()
		add_child(ambient_layer)
	if MelodyLayer:
		melody_layer = MelodyLayer.new()
		add_child(melody_layer)
	if EffectLayer:
		effect_layer = EffectLayer.new()
		add_child(effect_layer)

func update_flow(value: float):
	if ambient_layer: ambient_layer.update_flow(value)
	if melody_layer: melody_layer.update_flow(value)

func on_combo_hit(combo: int, multiplier: float):
	if melody_layer: melody_layer.on_combo_hit(combo, multiplier)

func on_damage_taken():
	if effect_layer: effect_layer.trigger_damage_effect()

func on_state_change(state: String):
	if ambient_layer: ambient_layer.on_state_change(state)

func on_beat(beat: int):
	if ambient_layer: ambient_layer.on_beat(beat)
	if melody_layer: melody_layer.on_beat(beat)
	if effect_layer: effect_layer.on_beat(beat)

func set_bpm(bpm: int):
	if ambient_layer: ambient_layer.set_bpm(bpm)
	if melody_layer: melody_layer.set_bpm(bpm)
