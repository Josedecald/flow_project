# autoloads/AudioManager.gd
extends Node

# Señales internas (opcionales para depuración)
signal bpm_changed(bpm: int)
signal flow_updated(value: float)
signal combo_hit(combo: int, multiplier: float)
signal state_updated(state: String)
signal damage_taken()

# El motor musical
const MusicEngine = preload("res://audio/MusicEngine.gd")
var music_engine

# Configuración rítmica
var bpm: int = 120
var beat_interval: float = 0.5  # 60 / bpm
var beat_timer: float = 0.0
var current_beat: int = 0
var beats_per_measure: int = 4

func _ready():
	# Inicializar el motor musical
	music_engine = MusicEngine.new()
	add_child(music_engine)
	
	# Configuración inicial
	music_engine.set_bpm(bpm)

func _process(delta):
	# Reloj musical
	beat_timer += delta
	if beat_timer >= beat_interval:
		beat_timer = 0.0
		current_beat = (current_beat + 1) % beats_per_measure
		music_engine.on_beat(current_beat)

# ============================================================
#  FUNCIONES PARA SER LLAMADAS DESDE EL JUGADOR
# ============================================================
func update_flow(value: float):
	flow_updated.emit(value)
	music_engine.update_flow(value)

func register_combo_hit(combo: int, multiplier: float):
	combo_hit.emit(combo, multiplier)
	music_engine.on_combo_hit(combo, multiplier)

func set_state(state: String):
	state_updated.emit(state)
	music_engine.on_state_change(state)

func register_damage():
	damage_taken.emit()
	music_engine.on_damage_taken()

func set_bpm(new_bpm: int):
	bpm = new_bpm
	beat_interval = 60.0 / bpm
	bpm_changed.emit(bpm)
	music_engine.set_bpm(bpm)

# Función auxiliar para conectar señales del jugador
func connect_signals(player: Node):
	# Conectar las señales del player a las funciones del AudioManager
	player.flow_changed.connect(update_flow)
	player.combo_changed.connect(register_combo_hit)
	player.state_changed.connect(set_state)
	# Para el daño, el player llamará directamente a register_damage()
