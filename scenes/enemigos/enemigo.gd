extends CharacterBody2D

## Enemigo genérico: persigue al Personaje, hace daño por contacto y muere al
## recibir suficiente daño. Reutilizable por los distintos enemigos
## (slime, cactus, flama_invierno...) mediante @export. Puede soltar monedas
## e items del inventario al morir.

signal murio

@export var vida_maxima: int = 3
@export var velocidad: float = 45.0
@export var radio_deteccion: float = 90.0
@export var dano_contacto: int = 1
@export var cadencia_dano: float = 1.0
@export var empuje: float = 110.0
@export var duracion_empuje: float = 0.15
@export var monedas_al_morir: int = 1
@export var escena_moneda: PackedScene = preload("res://scenes/items/moneda.tscn")
@export var items_al_morir: Array[StringName] = []
@export var escena_item: PackedScene = preload("res://scenes/items/item_recogible.tscn")

var vida: int = 0
var _jugador: Node2D = null
var _muerto: bool = false
var _puede_danar: bool = true
var _empuje_restante: float = 0.0
var _direccion_empuje: Vector2 = Vector2.ZERO

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


func _physics_process(delta: float) -> void:
	if _muerto:
		return

	if _empuje_restante > 0.0:
		_empuje_restante -= delta
		velocity = _direccion_empuje * empuje * (_empuje_restante / duracion_empuje)
		move_and_slide()
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
		_direccion_empuje = (global_position - _jugador.global_position).normalized()
		_empuje_restante = duracion_empuje
		velocity = _direccion_empuje * empuje
		move_and_slide()
	if vida <= 0:
		morir()


func _flash() -> void:
	_sprite.modulate = Color(1, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func _soltar_monedas() -> void:
	if escena_moneda == null or monedas_al_morir <= 0:
		return
	var escena := get_tree().current_scene
	if escena == null:
		return
	for i in monedas_al_morir:
		var moneda := escena_moneda.instantiate() as Node2D
		moneda.position = global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		escena.call_deferred("add_child", moneda)


func _soltar_items() -> void:
	if escena_item == null or items_al_morir.is_empty():
		return
	var escena := get_tree().current_scene
	if escena == null:
		return
	for id in items_al_morir:
		var item := escena_item.instantiate() as Node2D
		item.item_id = id
		item.position = global_position + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		escena.call_deferred("add_child", item)


func morir() -> void:
	if _muerto:
		return
	_muerto = true
	_soltar_monedas()
	_soltar_items()
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
