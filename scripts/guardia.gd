extends "res://scripts/npc_dialogo.gd"

## NPC que hace guardia: patrulla en vertical (arriba/abajo) sin dejar de
## poder dialogar. La animación cambia según el sentido del movimiento.

@export var velocidad: float = 24.0
@export var recorrido: float = 40.0

var _origen: Vector2
var _sentido: int = 1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	super._ready()
	_origen = position


func _physics_process(delta: float) -> void:
	if _dialogo_activo:
		_sprite.stop()
		return

	position.y += velocidad * _sentido * delta

	if _sentido > 0 and position.y >= _origen.y + recorrido:
		position.y = _origen.y + recorrido
		_sentido = -1
	elif _sentido < 0 and position.y <= _origen.y:
		position.y = _origen.y
		_sentido = 1

	_sprite.play("caminar_abajo" if _sentido > 0 else "caminar_arriba")
