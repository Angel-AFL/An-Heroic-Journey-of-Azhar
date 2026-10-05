extends Area2D

## Proyectil de las armas a distancia: avanza en línea recta, daña al primer
## enemigo que toca y se libera al chocar con un muro o al agotar su duración.
## El Personaje lo configura al instanciarlo (daño, textura, velocidad, dirección).

@export var dano: int = 1
@export var velocidad: float = 240.0
@export var duracion: float = 2.0
@export var textura: Texture2D
@export var direccion: Vector2 = Vector2.RIGHT

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _timer: Timer = $TimerDuracion


func _ready() -> void:
	if textura != null:
		_sprite.texture = textura
	rotation = direccion.angle()
	body_entered.connect(_on_body_entered)
	_timer.timeout.connect(queue_free)
	_timer.wait_time = duracion
	_timer.start()


func _physics_process(delta: float) -> void:
	position += direccion * velocidad * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("personaje"):
		return
	if body.has_method("recibir_dano"):
		body.recibir_dano(dano)
	queue_free()
