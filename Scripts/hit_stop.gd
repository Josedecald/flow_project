extends Node

## Autoload. Pausa brevemente el tiempo del juego (freeze frame) para dar
## peso a los golpes. Pensado para reutilizarse en Acorde de Impacto,
## Contrapunto, Fortissimo, y cualquier mecánica de combate futura.
##
## Uso:
##   HitStop.freeze(0.05)              # freeze corto, golpe normal
##   HitStop.freeze(0.12, 0.05)        # freeze más largo, golpe grande

var _active_timer: SceneTreeTimer


func freeze(duration: float = 0.05, time_scale: float = 0.05) -> void:

	Engine.time_scale = time_scale

	# Si ya había un freeze en curso, lo reemplaza en vez de acumularse.
	if _active_timer:
		_active_timer.timeout.disconnect(_end_freeze)

	# get_tree().create_timer con `true` en el 3er argumento ignora
	# el time_scale, para que el freeze termine en tiempo real.
	_active_timer = get_tree().create_timer(duration, true, false, true)
	_active_timer.timeout.connect(_end_freeze)


func _end_freeze() -> void:
	Engine.time_scale = 1.0
	_active_timer = null
