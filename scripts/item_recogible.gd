extends Area2D

## Objeto recogible genérico: al tocar al Personaje lo añade al inventario
## global y desaparece. El sprite se toma del catálogo según el "item_id".

const InventarioTipo = preload("res://scripts/inventario.gd")
const CatalogoItems = preload("res://scripts/catalogo_items.gd")
const EquipoTipo = preload("res://scripts/equipo.gd")
const SonidoTipo = preload("res://scripts/sonido.gd")
const SONIDO_RECOGIDA: AudioStream = preload("res://audio/moneda.wav")

@export var item_id: StringName = &""
@export var cantidad: int = 1

var _recogido: bool = false
var _bob: Tween

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _inventario: InventarioTipo = get_node("/root/Inventario") as InventarioTipo
@onready var _equipo: EquipoTipo = get_node("/root/Equipo") as EquipoTipo
@onready var _sonido: SonidoTipo = get_node("/root/Sonido") as SonidoTipo


func _ready() -> void:
	var icono := CatalogoItems.icono(item_id)
	if icono != null:
		_sprite.texture = icono
	body_entered.connect(_on_body_entered)
	_iniciar_brinco()


func _iniciar_brinco() -> void:
	var y: float = _sprite.position.y
	_bob = create_tween().set_loops()
	_bob.tween_property(_sprite, "position:y", y - 2.0, 0.5)
	_bob.tween_property(_sprite, "position:y", y, 0.5)


func _on_body_entered(body: Node2D) -> void:
	if _recogido:
		return
	if not body.is_in_group("personaje"):
		return
	if not _puede_recoger():
		return
	_recogido = true
	_inventario.agregar(item_id, cantidad)
	_sonido.reproducir(SONIDO_RECOGIDA)
	set_deferred("monitoring", false)
	if _bob != null:
		_bob.kill()
	_animar_recogida()


## Las armas son objetos únicos: no se recogen si ya se tienen o están equipadas al Personaje.
func _puede_recoger() -> bool:
	if CatalogoItems.maximo(item_id) != 1:
		return true
	return not _inventario.tiene(item_id) and not _equipo.esta_equipada(item_id)


func _animar_recogida() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "position:y", _sprite.position.y - 6.0, 0.2)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
