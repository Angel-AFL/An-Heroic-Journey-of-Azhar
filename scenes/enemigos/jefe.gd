extends "res://scenes/enemigos/enemigo.gd"

## Jefe de bioma: extiende el enemigo genérico con mucha más vida y daño, una
## barra de vida propia en el HUD, un ataque especial de proyectiles en abanico
## y una segunda fase (más rápido) al bajar de cierto umbral de vida.

signal vida_cambiada(vida_actual: int, vida_maxima: int)

@export_group("Jefe")
@export var nombre: String = "Jefe"
@export var ataque_especial_activo: bool = true
@export var ataque_especial_cooldown: float = 3.5
@export var preparacion_especial: float = 0.5
@export var proyectiles_especial: int = 8
@export var dano_especial: int = 2
@export var velocidad_proyectil_especial: float = 170.0
@export var duracion_proyectil_especial: float = 3.0
## Fracción de vida (0..1) a partir de la cual el jefe entra en fase 2.
@export var umbral_fase: float = 0.5
@export var multiplicador_fase2: float = 1.4
@export var escena_proyectil: PackedScene = preload("res://scenes/proyectiles/proyectil.tscn")

var _cooldown_especial_restante: float = 0.0
var _fase: int = 1
var _hud_barra: Node = null


func _ready() -> void:
	super()
	add_to_group("jefe")
	vida_cambiada.emit(vida, vida_maxima)
	_hud_barra = get_tree().get_first_node_in_group("hud_jefe")
	if is_instance_valid(_hud_barra):
		_hud_barra.mostrar(self)
	_cooldown_especial_restante = ataque_especial_cooldown


func _physics_process(delta: float) -> void:
	super(delta)
	if _muerto:
		return
	if _cooldown_especial_restante > 0.0:
		_cooldown_especial_restante = maxf(_cooldown_especial_restante - delta, 0.0)
	if _puede_especial():
		_iniciar_especial()


func _puede_especial() -> bool:
	if not ataque_especial_activo or _cooldown_especial_restante > 0.0:
		return false
	if not is_instance_valid(_jugador):
		return false
	var dist := global_position.distance_to(_jugador.global_position)
	return dist > 0.0 and dist <= radio_deteccion


func _iniciar_especial() -> void:
	var factor := multiplicador_fase2 if _fase >= 2 else 1.0
	_cooldown_especial_restante = ataque_especial_cooldown / factor
	_telegrafiar_especial()
	await get_tree().create_timer(preparacion_especial).timeout
	if _muerto or not is_inside_tree():
		return
	_disparar_abanico()


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
		escena.add_child(proyectil)
		proyectil.global_position = global_position + proyectil.direccion * 14.0


func recibir_dano(cantidad: int) -> void:
	if _muerto or cantidad <= 0:
		return
	super(cantidad)
	vida_cambiada.emit(vida, vida_maxima)
	_comprobar_fase()


func _comprobar_fase() -> void:
	if _muerto or _fase >= 2 or vida_maxima <= 0:
		return
	if float(vida) / float(vida_maxima) <= umbral_fase:
		_fase = 2
		velocidad *= multiplicador_fase2
		_sprite.modulate = Color(1.0, 0.6, 0.6)


func _telegrafiar_especial() -> void:
	_sprite.modulate = Color(0.7, 0.85, 1.0)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, preparacion_especial)


func morir() -> void:
	if is_instance_valid(_hud_barra):
		_hud_barra.ocultar()
	super()
