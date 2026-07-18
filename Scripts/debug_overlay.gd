extends CanvasLayer

## Autoload. Overlay de debug en pantalla, toggle con F3.
## Cualquier script llama DebugOverlay.set_value("nombre", valor) cada frame
## (o cuando cambie) y el overlay lo muestra. No hace falta declarar nada
## de antemano — el diccionario crece solo.
##
## Uso típico, en el _physics_process de player.gd:
##   DebugOverlay.set_value("flow", flow_system.flow)
##   DebugOverlay.set_value("state", StateMachine.State.keys()[state_machine.current_state])
##   DebugOverlay.set_value("knockback", knockback.is_active)

var _values: Dictionary = {}
var _label: Label
var _visible: bool = true


func _ready() -> void:
	layer = 100

	_label = Label.new()
	_label.position = Vector2(12, 12)
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_label.add_theme_constant_override("shadow_offset_x", 1)
	_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_label)


func _process(_delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_F3) and not _f3_was_pressed:
		_visible = not _visible
		_label.visible = _visible
	_f3_was_pressed = Input.is_physical_key_pressed(KEY_F3)

	if not _visible:
		return

	var text := ""
	for key in _values.keys():
		text += "%s: %s\n" % [key, str(_values[key])]
	_label.text = text

var _f3_was_pressed: bool = false


func set_value(key: String, value) -> void:
	_values[key] = value
