# audio/layers/AmbientLayer.gd
extends Node

@onready var audio_player = AudioStreamPlayer.new()
var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100

var bpm: int = 120
var flow: float = 0.0
var state: String = "IDLE"
var beat: int = 0
var measure: int = 0

# Progresión de acordes (Do - Sol - Am - Fa)
const CHORDS = {
	"C": [261.63, 329.63, 392.00],
	"G": [392.00, 493.88, 587.33],
	"Am": [220.00, 261.63, 329.63],
	"F": [349.23, 440.00, 523.25]
}

var chord_sequence = ["C", "G", "Am", "F"]
var current_chord_index: int = 0
var active_notes: Dictionary = {}  # freq -> {phase, elapsed, duration}

func _ready():
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.5
	audio_player.stream = stream
	add_child(audio_player)
	audio_player.play()
	playback = audio_player.get_stream_playback()
	
	# Iniciar con el primer acorde
	trigger_chord(chord_sequence[0])

func set_bpm(new_bpm: int):
	bpm = new_bpm

func update_flow(value: float):
	flow = value

func on_state_change(new_state: String):
	state = new_state
	# Cambiar la velocidad/volumen según estado
	update_arp_speed()

func on_beat(beat: int):
	self.beat = beat
	if beat == 0:
		measure += 1
		# Cambiar acorde cada 4 compases
		if measure % 4 == 0:
			current_chord_index = (current_chord_index + 1) % chord_sequence.size()
			trigger_chord(chord_sequence[current_chord_index])
	# Tocar arpegio suave en cada beat
	play_arpeggio()

func trigger_chord(chord_name: String):
	var notes = CHORDS[chord_name]
	for freq in notes:
		start_note(freq, 0.2, 0.5)  # Volumen bajo, duración larga

func play_arpeggio():
	# Arpegio ascendente con volumen según flow
	var notes = CHORDS[chord_sequence[current_chord_index]]
	var volume = 0.05 + flow * 0.002  # Más flow = más volumen
	var note = notes[beat % notes.size()]
	start_note(note, volume, 0.2)

func start_note(freq: float, volume: float, duration: float):
	if playback and playback.get_frames_available() > 0:
		active_notes[freq] = {
			"volume": volume,
			"duration": duration,
			"elapsed": 0.0,
			"phase": 0.0
		}

func update_arp_speed():
	# Cambiar el ritmo del arpegio según estado (ej: más rápido en SPRINT)
	pass

func _process(delta):
	if not playback:
		return
	
	var frames = playback.get_frames_available()
	if frames == 0:
		return
	
	var buffer = Vector2.ZERO
	var notes_to_remove = []
	
	for freq in active_notes.keys():
		var note = active_notes[freq]
		note.elapsed += delta
		
		# Envolvente: decaimiento exponencial
		var vol = note.volume * exp(-note.elapsed * 3.0)
		if note.elapsed >= note.duration or vol < 0.001:
			notes_to_remove.append(freq)
			continue
		
		# Onda sinusoidal con armónicos suaves
		var phase = note.phase
		var sample = sin(phase * TAU) * vol
		sample += sin(phase * TAU * 2) * vol * 0.2
		sample += sin(phase * TAU * 3) * vol * 0.1
		buffer += Vector2(sample, sample)
		
		note.phase = fmod(phase + freq / sample_rate, 1.0)
	
	for freq in notes_to_remove:
		active_notes.erase(freq)
	
	# Enviar al buffer (controlar volumen general)
	for i in range(min(frames, 256)):
		playback.push_frame(buffer * 0.3)
