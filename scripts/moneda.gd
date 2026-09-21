extends Area2D

## Moneda recogible: al tocar al Personaje suma al monedero global y
## desaparece. El total se conserva entre escenarios (autoload Monedero).

const MonederoTipo = preload("res://scripts/monedero.gd")

@export var valor: int = 1

var _recogida: bool = false
var _bob: Tween

@onready var _monedero: MonederoTipo = get_node("/root/Monedero") as MonederoTipo


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_iniciar_brinco()


func _iniciar_brinco() -> void:
	var sprite: Sprite2D = $Sprite2D
	var y: float = sprite.position.y
	_bob = create_tween().set_loops()
	_bob.tween_property(sprite, "position:y", y - 2.0, 0.5)
	_bob.tween_property(sprite, "position:y", y, 0.5)


func _on_body_entered(body: Node2D) -> void:
	if _recogida:
		return
	if not body.is_in_group("personaje"):
		return
	_recogida = true
	_monedero.agregar(valor)
	set_deferred("monitoring", false)
	if _bob != null:
		_bob.kill()
	_animar_recogida()


func _animar_recogida() -> void:
	var sprite: Sprite2D = $Sprite2D
	var tween := create_tween()
	tween.tween_property(sprite, "position:y", sprite.position.y - 6.0, 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
