extends "res://scenes/enemigos/jefe.gd"

## Jefe final Guardián del Eclipse: combina la embestida del Señor del
## Hielo, los picos del Cactus Ancestral y una invocación periódica de
## esbirros de los tres biomas.

const ESTADO_NORMAL: int = 0
const GRUPO_INVOCADOS: StringName = &"invocados_eclipse"
const ESCENAS_INVOCADOS: Array[PackedScene] = [
	preload("res://scenes/enemigos/slime.tscn"),
	preload("res://scenes/enemigos/cactus.tscn"),
	preload("res://scenes/enemigos/flama_invierno.tscn"),
]

@export_group("Proyectil alterno")
@export var textura_proyectil_alterna: Texture2D
@export var region_proyectil_alterna: Rect2 = Rect2()
@export var escala_proyectil_alterna: float = 1.0

@export_group("Invocación")
@export var invocacion_activa: bool = true
@export var intervalo_invocacion: float = 8.0
@export var intervalo_invocacion_fase2: float = 6.0
@export var cantidad_invocados: int = 2
@export var max_invocados: int = 5

var _cooldown_invocacion: float = 0.0
var _indice_invocado: int = 0
var _invocando: bool = false
var _timer_invocacion: Timer
var _tiempo_orbita: float = 0.0

@onready var _aura: Sprite2D = $Aura
@onready var _orbes: Array = [$OrbeBosque, $OrbeDesierto, $OrbeNieve]


func _ready() -> void:
	super()
	_cooldown_invocacion = intervalo_invocacion
	_timer_invocacion = Timer.new()
	_timer_invocacion.one_shot = true
	_timer_invocacion.wait_time = 0.45
	_timer_invocacion.timeout.connect(_on_invocacion_timeout)
	add_child(_timer_invocacion)
	_animar_aura()
	_animar_flotacion()


func _animar_aura() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(_aura, "modulate:a", 0.55, 1.2)
	tween.tween_property(_aura, "modulate:a", 0.3, 1.2)


func _animar_flotacion() -> void:
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_sprite, "position:y", -2.0, 1.0)
	tween.tween_property(_sprite, "position:y", 0.0, 1.0)


func _physics_process(delta: float) -> void:
	super(delta)
	if _muerto:
		return
	_actualizar_orbes(delta)
	if not invocacion_activa:
		return
	if _cargando or _estado != ESTADO_NORMAL:
		return
	_cooldown_invocacion -= delta
	if _cooldown_invocacion > 0.0:
		return
	_invocar()
	_cooldown_invocacion = intervalo_invocacion_fase2 if _fase >= 2 else intervalo_invocacion


## La lluvia de picos solo empieza si el jefe está libre (sin embestida ni invocación).
func _puede_especial() -> bool:
	if _estado != ESTADO_NORMAL or _cargando or _invocando:
		return false
	return super()


## La embestida espera a que termine la invocación.
func _puede_embestir(hacia: Vector2) -> bool:
	if _invocando:
		return false
	return super(hacia)


## Abanico alternando picos verdes y picos de hielo.
func _disparar_abanico() -> void:
	if escena_proyectil == null:
		return
	var escena := get_tree().current_scene
	if escena == null:
		return
	var base := Vector2.RIGHT
	if is_instance_valid(_jugador):
		base = (_jugador.global_position - global_position).normalized()
	var cantidad := maxi(proyectiles_especial, 1)
	var paso := TAU / float(cantidad)
	for i in cantidad:
		var proyectil := escena_proyectil.instantiate()
		proyectil.dano = dano_especial
		proyectil.velocidad = velocidad_proyectil_especial
		proyectil.duracion = duracion_proyectil_especial
		proyectil.direccion = base.rotated(paso * float(i))
		proyectil.de_enemigo = true
		if i % 2 == 0:
			proyectil.textura = textura_proyectil
			proyectil.region = region_proyectil
			proyectil.escala = escala_proyectil
		else:
			proyectil.textura = textura_proyectil_alterna
			proyectil.region = region_proyectil_alterna
			proyectil.escala = escala_proyectil_alterna
		escena.add_child(proyectil)
		proyectil.global_position = global_position + proyectil.direccion * 16.0
	if sonido_ataque != null:
		_sonido.reproducir(sonido_ataque)
	_destello_salida()


func _invocar() -> void:
	var vivos := get_tree().get_nodes_in_group(GRUPO_INVOCADOS).size()
	var espacio := maxi(max_invocados - vivos, 0)
	var cantidad := mini(cantidad_invocados, espacio)
	if cantidad <= 0:
		return
	_invocando = true
	_telegrafiar_invocacion()
	_timer_invocacion.start()
	var escena := get_tree().current_scene
	if escena == null:
		return
	for i in cantidad:
		var recursos := ESCENAS_INVOCADOS[_indice_invocado % ESCENAS_INVOCADOS.size()]
		_indice_invocado += 1
		var esbirro := recursos.instantiate()
		esbirro.vida_maxima = 2
		esbirro.dano_contacto = 1
		esbirro.velocidad = 60.0
		esbirro.radio_deteccion = 260.0
		esbirro.monedas_al_morir = 0
		esbirro.add_to_group(GRUPO_INVOCADOS)
		var angulo := TAU * float(i) / float(cantidad) + randf_range(-0.25, 0.25)
		esbirro.position = global_position + Vector2(cos(angulo), sin(angulo)) * 56.0
		escena.call_deferred("add_child", esbirro)


func _actualizar_orbes(delta: float) -> void:
	_tiempo_orbita += delta
	for i in _orbes.size():
		var angulo := _tiempo_orbita * 1.2 + TAU * float(i) / float(_orbes.size())
		_orbes[i].position = Vector2(0, -16) + Vector2(cos(angulo), sin(angulo)) * 22.0


func _telegrafiar_invocacion() -> void:
	_sprite.modulate = Color(0.7, 0.35, 0.95, 1.0)
	var color_final := Color(1.0, 0.6, 0.6, 1.0) if _fase >= 2 else Color.WHITE
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", color_final, 0.45)


func _on_invocacion_timeout() -> void:
	_invocando = false


func morir() -> void:
	if _muerto:
		return
	for esbirro in get_tree().get_nodes_in_group(GRUPO_INVOCADOS):
		if is_instance_valid(esbirro):
			esbirro.queue_free()
	super()
