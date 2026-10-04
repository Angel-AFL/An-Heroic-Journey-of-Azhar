extends CharacterBody2D

## Enemigo genérico: persigue al Personaje, hace daño por contacto y muere al
## recibir suficiente daño. Reutilizable por los distintos enemigos
## (slime, cactus, flama_invierno...) mediante @export. Puede soltar monedas
## e items del inventario al morir.

signal murio

enum Estado { NORMAL, PREPARACION, EMBESTIDA }

@export var vida_maxima: int = 5
@export var velocidad: float = 78.0
@export var radio_deteccion: float = 90.0
@export var dano_contacto: int = 1
@export var cadencia_dano: float = 0.55
@export var empuje: float = 150.0
@export var duracion_empuje: float = 0.2
@export var monedas_al_morir: int = 1
@export var escena_moneda: PackedScene = preload("res://scenes/items/moneda.tscn")
@export var items_al_morir: Array[StringName] = []
@export var escena_item: PackedScene = preload("res://scenes/items/item_recogible.tscn")

@export_group("Persecución")
## Segundos que sigue hacia la última posición conocida tras perder de vista al jugador.
@export var persecucion_memoria: float = 0.0
## Aceleración (px/s²) al arrancar/frenar. 0 = velocidad instantánea (comportamiento previo).
@export var aceleracion: float = 0.0
## Radio en el que se separa de otros enemigos para no apilarse. 0 = desactivado.
@export var separacion: float = 0.0

@export_group("Embestida")
## Activa el ataque de embestida telegrafiada.
@export var embestida_activa: bool = false
@export var velocidad_embestida: float = 300.0
@export var duracion_embestida: float = 0.4
@export var cooldown_embestida: float = 1.4
@export var preparacion_embestida: float = 0.35
@export var dano_embestida: int = 2
## Distancia al jugador desde la que puede iniciar la embestida.
@export var distancia_embestida: float = 120.0

var vida: int = 0
var _jugador: Node2D = null
var _muerto: bool = false
var _puede_danar: bool = true
var _empuje_restante: float = 0.0
var _direccion_empuje: Vector2 = Vector2.ZERO
var _estado: int = Estado.NORMAL
var _tiempo_estado: float = 0.0
var _cooldown_embestida_restante: float = 0.0
var _direccion_embestida: Vector2 = Vector2.ZERO
var _ultima_pos_jugador: Vector2 = Vector2.ZERO
var _memoria_restante: float = 0.0

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

	if _cooldown_embestida_restante > 0.0:
		_cooldown_embestida_restante = maxf(_cooldown_embestida_restante - delta, 0.0)

	_actualizar_jugador()

	match _estado:
		Estado.PREPARACION:
			_procesar_preparacion(delta)
		Estado.EMBESTIDA:
			_procesar_embestida(delta)
		_:
			_procesar_normal(delta)

	_intentar_danar_contacto()


func _procesar_normal(delta: float) -> void:
	if is_instance_valid(_jugador):
		var hacia_jugador := _jugador.global_position - global_position
		if _puede_embestir(hacia_jugador):
			_iniciar_preparacion(hacia_jugador.normalized())
			return

	var deseada := Vector2.ZERO
	if _persigue(delta):
		deseada = (_ultima_pos_jugador - global_position).normalized() * velocidad + _vector_separacion()
	_velocidad_hacia(deseada, delta)
	move_and_slide()


func _procesar_preparacion(delta: float) -> void:
	velocity = Vector2.ZERO
	_tiempo_estado -= delta
	if _tiempo_estado <= 0.0:
		_iniciar_embestida()
	move_and_slide()


func _procesar_embestida(delta: float) -> void:
	velocity = _direccion_embestida * velocidad_embestida
	_tiempo_estado -= delta
	if _tiempo_estado <= 0.0:
		_estado = Estado.NORMAL
		_cooldown_embestida_restante = cooldown_embestida
	move_and_slide()


func _puede_embestir(hacia: Vector2) -> bool:
	if not embestida_activa or _cooldown_embestida_restante > 0.0:
		return false
	var dist := hacia.length()
	return dist > 0.0 and dist <= radio_deteccion and dist <= distancia_embestida


func _iniciar_preparacion(dir: Vector2) -> void:
	_estado = Estado.PREPARACION
	_tiempo_estado = preparacion_embestida
	_direccion_embestida = dir
	velocity = Vector2.ZERO
	_telegrafiar_embestida()


func _iniciar_embestida() -> void:
	_estado = Estado.EMBESTIDA
	_tiempo_estado = duracion_embestida
	velocity = _direccion_embestida * velocidad_embestida


func _persigue(delta: float) -> bool:
	if not is_instance_valid(_jugador):
		return false

	var hacia := _jugador.global_position - global_position
	if hacia.length() <= radio_deteccion:
		_ultima_pos_jugador = _jugador.global_position
		_memoria_restante = persecucion_memoria
		return true

	if _memoria_restante > 0.0:
		_memoria_restante -= delta
		if (_ultima_pos_jugador - global_position).length() > 4.0:
			return true
		_memoria_restante = 0.0

	return false


func _vector_separacion() -> Vector2:
	if separacion <= 0.0:
		return Vector2.ZERO
	var acumulado := Vector2.ZERO
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if enemigo == self or not is_instance_valid(enemigo) or enemigo.get("_muerto"):
			continue
		var diff: Vector2 = global_position - enemigo.global_position
		var dist := diff.length()
		if dist > 0.0 and dist < separacion:
			acumulado += diff.normalized() * (1.0 - dist / separacion)
	return acumulado * velocidad


func _velocidad_hacia(deseada: Vector2, delta: float) -> void:
	if aceleracion > 0.0:
		velocity = velocity.move_toward(deseada, aceleracion * delta)
	else:
		velocity = deseada


func _actualizar_jugador() -> void:
	if is_instance_valid(_jugador):
		return
	_jugador = get_tree().get_first_node_in_group("personaje")


func _intentar_danar_contacto() -> void:
	if not _puede_danar:
		return
	var dano := dano_embestida if _estado == Estado.EMBESTIDA else dano_contacto
	for cuerpo in _zona_contacto.get_overlapping_bodies():
		if cuerpo.is_in_group("personaje") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano)
			_puede_danar = false
			_timer_dano.start()
			break


func _on_timer_dano_timeout() -> void:
	_puede_danar = true


func recibir_dano(cantidad: int) -> void:
	if _muerto or cantidad <= 0:
		return
	vida -= cantidad
	_estado = Estado.NORMAL
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


func _telegrafiar_embestida() -> void:
	_sprite.modulate = Color(1.0, 0.85, 0.3)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, preparacion_embestida)


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
