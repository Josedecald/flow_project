extends Camera2D

@onready var player: CharacterBody2D = $"../Player"

var noise: FastNoiseLite
var noise_y := 0.0

var trauma := 0.0

@export var trauma_power := 2.0
@export var decay := 0.8
@export var max_offset := Vector2(10,8)
@export var shake_speed := 30.0

@export var zoom_min := 0.7
@export var zoom_max := 1.5
@export var smooth_velocity := 5.0


func _ready():

	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.1


func _physics_process(delta):

	global_position = global_position.lerp(player.global_position,0.35)

	if trauma > 0:
		trauma = max(trauma - decay * delta,0.0)
		camera_shake(delta)
	else:
		offset = Vector2.ZERO

	zoom_camera(delta)


func add_trauma(amount: float):

	trauma = min(trauma + amount,1.0)


func camera_shake(delta):

	var intensity = pow(trauma,trauma_power)

	noise_y += shake_speed * delta

	offset.x = noise.get_noise_2d(0,noise_y) * max_offset.x * intensity
	offset.y = noise.get_noise_2d(100,noise_y) * max_offset.y * intensity


func zoom_camera(delta):

	var target = remap(
		clamp(player.flow,0.0,100.0),
		0.0,
		100.0,
		zoom_max,
		zoom_min
	)

	zoom = zoom.lerp(
		Vector2.ONE * target,
		smooth_velocity * delta
	)
