extends Area2D
class_name Hurtbox

signal hit(hitbox)
@onready var health: Health
@onready var knockback: Knockback

@export var invulnerability_time: float = 0.15
var invulnerable: bool = false
var invulnerability_timer: float = 0.0

func _ready():
	health = get_parent().get_node("Health") as Health
	knockback = get_parent().get_node("Knockback") as Knockback

func _process(delta: float) -> void:
	if not invulnerable:
		return
	invulnerability_timer -= delta
	if invulnerability_timer <= 0:
		invulnerable = false
		invulnerability_timer = 0

func _on_area_entered(area: Area2D) -> void:
	if not area is Hitbox:
		return
	if invulnerable:
		return

	health.take_damage(area.damage)

	if knockback:
		var direction = (owner.global_position - area.global_position)
		if direction.is_zero_approx():
			direction = Vector2.RIGHT
		knockback.apply(direction, area.knockback_force)

	invulnerable = true
	invulnerability_timer = invulnerability_time
