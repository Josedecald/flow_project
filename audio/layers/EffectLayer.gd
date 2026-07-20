# audio/layers/EffectLayer.gd
extends Node

@onready var audio_player = AudioStreamPlayer.new()
var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100

var flow: float = 0.0
var state: String = "IDLE"
var damage_effect_active: bool = false
var damage_timer: float = 0.0

func _ready():
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.2
	audio_player.stream = stream
	add_child(audio_player)
	audio_player.play()
	playback = audio_player.get_stream_playback()

func set_bpm(bpm: int):
	pass

func update_flow(value: float):
	flow = value

func on_beat(beat: int):
	# Si el estado es HURT, reproducir un sonido de "desafinado" rítmico
	if state == "HURT" and beat % 2 == 0:
		play_dissonant_note()

func on_state_change(new_state: String):
	state = new_state

func trigger_damage_effect():
	damage_effect_active = true
	damage_timer = 0.5
	# Reproducir un glissando descendente (desafinado)
	play_glissando(440.0, 220.0, 0.3)

func play_dissonant_note():
	# Reproducir una nota ligeramente desafinada
	var freq = 300.0 + randf() * 40.0  # Entre 300 y 340 Hz (entre Re y Fa)
	play_note(freq, 0.2, 0.15)

func play_glissando(start_freq: float, end_freq: float, duration: float):
	if not playback:
		return
	var frames = playback.get_frames_available()
	if frames < 128:
		return
	
	var sample_count = int(duration * sample_rate)
	var buffer = Vector2.ZERO
	var phase = 0.0
	
	for i in range(min(sample_count, frames)):
		var t = i / float(sample_count)
		var freq = lerp(start_freq, end_freq, t)
		var env = exp(-t * 4.0) * (1.0 - exp(-t * 20.0))
		var sample = sin(phase * TAU) * env * 0.4
		buffer += Vector2(sample, sample)
		phase = fmod(phase + freq / sample_rate, 1.0)
	
	for i in range(min(sample_count, frames)):
		playback.push_frame(buffer)

func play_note(freq: float, volume: float, duration: float):
	if not playback:
		return
	var frames = playback.get_frames_available()
	if frames < 64:
		return
	
	var sample_count = int(duration * sample_rate)
	var buffer = Vector2.ZERO
	var phase = 0.0
	
	for i in range(min(sample_count, frames)):
		var env = exp(-i / float(sample_count) * 3.0)
		var sample = sin(phase * TAU) * env * volume
		buffer += Vector2(sample, sample)
		phase = fmod(phase + freq / sample_rate, 1.0)
	
	for i in range(min(sample_count, frames)):
		playback.push_frame(buffer)

func _process(delta):
	if damage_effect_active:
		damage_timer -= delta
		if damage_timer <= 0.0:
			damage_effect_active = false
