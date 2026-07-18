extends Node
class_name Flash

@export var duration: float = 0.08

const FLASH_SHADER := preload("res://components/flash/flash.gdshader")

var flash_material: ShaderMaterial
var sprite: CanvasItem

func _ready() -> void:
	# 1. Buscamos el sprite primero
	sprite = find_sprite(owner)
	
	# 2. Verificamos SIEMPRE si es null antes de operar con él
	if sprite == null:
		push_error("Flash: No se encontró ningún sprite en la escena de: ", owner.name)
		return # Detiene la ejecución para evitar errores en las líneas siguientes
		
	# 3. Si existe, creamos y asignamos el material de forma segura
	flash_material = ShaderMaterial.new()
	flash_material.shader = FLASH_SHADER
	sprite.material = flash_material

func find_sprite(node: Node) -> CanvasItem:
	if node == null:
		return null

	# Comprueba si el nodo actual está en el grupo "sprites" y es un objeto visual
	if node.is_in_group("sprites") and node is CanvasItem:
		return node

	# Búsqueda recursiva en los hijos
	for child in node.get_children():
		var result := find_sprite(child)
		if result:
			return result

	return null
	
func flash() -> void:
	# Evita que el juego se rompa si se llama a flash() pero no hay un sprite válido
	if sprite == null or flash_material == null:
		return

	flash_material.set_shader_parameter("flash_amount", 1.0)
	await get_tree().create_timer(duration).timeout
	flash_material.set_shader_parameter("flash_amount", 0.0)
