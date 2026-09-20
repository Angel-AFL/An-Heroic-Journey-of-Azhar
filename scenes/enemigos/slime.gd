extends CharacterBody2D

## Enemigo slime: persigue al Personaje, hace daño por contacto y muere al
## recibir suficiente daño. Pensado para reutilizarse en otros enemigos.

signal murio

@export var vida_maxima: int = 3
@export var velocidad: float = 45.0
@export var radio_deteccion: float = 90.0
@export var dano_contacto: int = 1
@export var cadencia_dano: float = 1.0
@export var empuje: float = 110.0

var vida: int = 0
var _jugador: Node2D = null
var _muerto: bool = false
var _puede_danar: bool = true

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _zona_contacto: Area2D = $ZonaContacto
@onready var _sprite_muerte: Sprite2D = $SpriteMuerte
@onready var _timer_dano: Timer = $TimerDano
@onready var _colision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group("enemigos")
	vida = vida_maxima
	_sprite_muerte.hide()
	_timer_dano.one_shot = true
	_timer_dano.wait_time = cadencia_dano
	_timer_dano.timeout.connect(_on_timer_dano_timeout)


func _physics_process(_delta: float) -> void:
	if _muerto:
		return

	_actualizar_jugador()

	if is_instance_valid(_jugador):
		var hacia := _jugador.global_position - global_position
		if hacia.length() <= radio_deteccion:
			velocity = hacia.normalized() * velocidad
			move_and_slide()
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	_intentar_danar_contacto()


func _actualizar_jugador() -> void:
	if is_instance_valid(_jugador):
		return
	_jugador = get_tree().get_first_node_in_group("personaje")


func _intentar_danar_contacto() -> void:
	if not _puede_danar:
		return
	for cuerpo in _zona_contacto.get_overlapping_bodies():
		if cuerpo.is_in_group("personaje") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano_contacto)
			_puede_danar = false
			_timer_dano.start()
			break


func _on_timer_dano_timeout() -> void:
	_puede_danar = true


func recibir_dano(cantidad: int) -> void:
	if _muerto or cantidad <= 0:
		return
	vida -= cantidad
	_flash()
	if is_instance_valid(_jugador):
		var direccion := (global_position - _jugador.global_position).normalized()
		velocity = direccion * empuje
		move_and_slide()
	if vida <= 0:
		morir()


func _flash() -> void:
	_sprite.modulate = Color(1, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func morir() -> void:
	if _muerto:
		return
	_muerto = true
	velocity = Vector2.ZERO
	_sprite.hide()
	_sprite_muerte.show()
	_zona_contacto.set_deferred("monitoring", false)
	_colision.set_deferred("disabled", true)
	set_physics_process(false)
	murio.emit()
	var tween := create_tween()
	tween.tween_property(_sprite_muerte, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
