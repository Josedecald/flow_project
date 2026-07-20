# audio/layers/MelodyLayer.gd
extends Node

@onready var audio_player = AudioStreamPlayer.new()
var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100

# Escala pentatónica de Do Mayor (siempre suena bien)
const SCALE = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25, 587.33, 659.25]
var flow: float = 0.0
var combo_count: int = 0
var note_index: int = 0

func _ready():
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.2
	audio_player.stream = stream
	add_child(audio_player)
	audio_player.play()
	playback = audio_player.get_stream_playback()

func set_bpm(bpm: int):
	pass  # Podríamos ajustar el tempo

func update_flow(value: float):
	flow = value

func on_combo_hit(combo: int, multiplier: float):
	combo_count = combo
	# Avanzar en la escala
	note_index = (combo - 1) % SCALE.size()
	var freq = SCALE[note_index]
	# Si el combo es múltiplo de 5, subir una octava
	if combo >= 5 and combo % 5 == 0:
		freq *= 2
	# Tocar la nota con brillo según combo
	var brightness = min(1.0, combo * 0.15)
	play_melody_note(freq, 0.3 + brightness * 0.5)

func play_melody_note(freq: float, volume: float):
	if not playback:
		return
	
	var frames = playback.get_frames_available()
	if frames < 64:
		return
	
	# Generar la nota con un ataque rápido
	var duration = 0.08 + combo_count * 0.01
	var sample_count = int(duration * sample_rate)
	var buffer = Vector2.ZERO
	var phase = 0.0
	
	for i in range(min(sample_count, frames)):
		var t = i / float(sample_count)
		# Envolvente: ataque rápido, decaimiento exponencial
		var env = exp(-t * 5.0) * (1.0 - exp(-t * 30.0))
		var sample = sin(phase * TAU) * env * volume
		# Añadir armónicos para sonido de piano
		sample += sin(phase * TAU * 2) * env * volume * 0.3
		sample += sin(phase * TAU * 3) * env * volume * 0.1
		buffer += Vector2(sample, sample)
		phase = fmod(phase + freq / sample_rate, 1.0)
	
	# Enviar al buffer
	for i in range(min(sample_count, frames)):
		playback.push_frame(buffer / 1.5)
