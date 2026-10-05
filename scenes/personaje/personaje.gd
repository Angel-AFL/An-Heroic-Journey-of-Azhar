extends CharacterBody2D

## Personaje jugable: movimiento direccional, ataque cuerpo a cuerpo con
## hitbox frontal, vida con invulnerabilidad temporal y muerte.

signal vida_cambiada(vida_actual: int, vida_maxima: int)
signal murio

const MejorasTipo = preload("res://scripts/mejoras.gd")
const SonidoTipo = preload("res://scripts/sonido.gd")
const EquipoTipo = preload("res://scripts/equipo.gd")
const CatalogoArmas = preload("res://scripts/catalogo_armas.gd")
const ESCENA_PROYECTIL: PackedScene = preload("res://scenes/proyectiles/proyectil.tscn")
const SONIDO_ATAQUE: AudioStream = preload("res://audio/ataque.wav")
const SONIDO_GOLPE_ENEMIGO: AudioStream = preload("res://audio/golpe-enemigo.wav")

@export var speed: float = 130.0
@export var attack_duration: float = 0.3
@export var vida_maxima: int = 3
@export var dano_ataque: int = 1
@export var invulnerabilidad: float = 0.8
@export var alcance_ataque: float = 22.0

var puede_moverse: bool = true
var atacando: bool = false
var direccion: Vector2 = Vector2.DOWN
var vida: int = 0
var _invulnerable: bool = false
var _golpeados: Array = []
var _arma_id: StringName = &""

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _attack_timer: Timer = $AttackTimer
@onready var _hitbox: Area2D = $Hitbox
@onready var _inv_timer: Timer = $InvulnerabilidadTimer
@onready var _arma: Sprite2D = $Arma
@onready var _mejoras: MejorasTipo = get_node("/root/Mejoras") as MejorasTipo
@onready var _sonido: SonidoTipo = get_node("/root/Sonido") as SonidoTipo
@onready var _equipo: EquipoTipo = get_node("/root/Equipo") as EquipoTipo


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	vida_maxima = _mejoras.vida_maxima()
	vida = _mejoras.vida_guardada()
	_attack_timer.wait_time = attack_duration
	_attack_timer.timeout.connect(_on_attack_finished)
	_inv_timer.one_shot = true
	_inv_timer.wait_time = invulnerabilidad
	_inv_timer.timeout.connect(_on_invulnerabilidad_fin)
	_hitbox.body_entered.connect(_on_hitbox_body_entered)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	_mejoras.cambiado.connect(sincronizar_vida_maxima)
	_arma_id = _equipo.arma_equipada()
	_equipo.arma_cambiada.connect(_on_arma_cambiada)
	vida_cambiada.emit(vida, vida_maxima)


func _physics_process(_delta: float) -> void:
	if not puede_moverse:
		velocity = Vector2.ZERO
		_play_idle()
		move_and_slide()
		return

	if atacando:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")

	if input_dir != Vector2.ZERO:
		direccion = input_dir
		velocity = input_dir * speed
		_play_walk(input_dir)
	else:
		velocity = Vector2.ZERO
		_play_idle()

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not puede_moverse or atacando:
		return

	if event.is_action_pressed("atacar"):
		atacando = true
		velocity = Vector2.ZERO

		var input_dir := Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
		if input_dir != Vector2.ZERO:
			direccion = input_dir

		_sprite.play("atacar-" + _dir_name(direccion))
		_attack_timer.wait_time = _cadencia_actual()
		_attack_timer.start()
		if _tipo_arma() == "rango":
			_disparar_proyectil()
		else:
			_activar_hitbox()
			if _arma_id != &"":
				_empunar_arma()


func _activar_hitbox() -> void:
	_golpeados.clear()
	_hitbox.position = _offset_hitbox()
	_hitbox.monitoring = true
	await get_tree().physics_frame
	if atacando:
		_golpear_en_hitbox()


func _empunar_arma() -> void:
	var textura := CatalogoArmas.sprite_mano(_arma_id)
	if textura != null:
		_arma.texture = textura
	_arma.visible = true
	match _dir_name(direccion):
		"derecha":
			_arma.position = Vector2(9, 4)
			_arma.rotation = PI / 2.0
		"izquierda":
			_arma.position = Vector2(-12, 5)
			_arma.rotation = -PI / 2.0
		"arriba":
			_arma.position = Vector2(0, -9)
			_arma.rotation = 0.0
		_:
			_arma.position = Vector2(0, 9)
			_arma.rotation = PI


func _guardar_arma() -> void:
	_arma.visible = false


func _disparar_proyectil() -> void:
	var textura := CatalogoArmas.proyectil(_arma_id)
	if textura == null:
		return
	var escena := get_tree().current_scene
	if escena == null:
		return
	var proyectil := ESCENA_PROYECTIL.instantiate()
	proyectil.dano = _dano_arma()
	proyectil.textura = textura
	proyectil.velocidad = CatalogoArmas.velocidad_proyectil(_arma_id)
	proyectil.direccion = direccion.normalized()
	escena.add_child(proyectil)
	proyectil.global_position = global_position + direccion.normalized() * 10.0


func _golpear_en_hitbox() -> void:
	for cuerpo in _hitbox.get_overlapping_bodies():
		_aplicar_golpe(cuerpo)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if not atacando:
		return
	_aplicar_golpe(body)


func _aplicar_golpe(cuerpo: Node) -> void:
	if _golpeados.has(cuerpo):
		return
	if not cuerpo.has_method("recibir_dano"):
		return
	if not (cuerpo is Node2D) or global_position.distance_to(cuerpo.global_position) > _alcance_actual():
		return
	_golpeados.append(cuerpo)
	_sonido.reproducir(SONIDO_ATAQUE)
	cuerpo.recibir_dano(_dano_arma())


func recibir_dano(cantidad: int) -> void:
	if cantidad <= 0 or _invulnerable or vida <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	_mejoras.establecer_vida(vida)
	vida_cambiada.emit(vida, vida_maxima)
	_sonido.reproducir(SONIDO_GOLPE_ENEMIGO)
	_invulnerable = true
	_inv_timer.start()
	_parpadear()
	if vida <= 0:
		_morir()


func sincronizar_vida_maxima(nuevo_maximo: int) -> void:
	vida_maxima = nuevo_maximo
	vida = _mejoras.vida_guardada()
	vida_cambiada.emit(vida, vida_maxima)


## Cura vida hasta el máximo. Devuelve false si ya está al máximo o si está muerto.
func curar(cantidad: int) -> bool:
	if cantidad <= 0 or vida <= 0 or vida >= vida_maxima:
		return false
	vida = mini(vida + cantidad, vida_maxima)
	_mejoras.establecer_vida(vida)
	vida_cambiada.emit(vida, vida_maxima)
	return true


func _on_arma_cambiada(id: StringName) -> void:
	_arma_id = id
	_guardar_arma()


func _tipo_arma() -> String:
	return CatalogoArmas.tipo(_arma_id)


func _dano_arma() -> int:
	return CatalogoArmas.dano(_arma_id, dano_ataque)


func _cadencia_actual() -> float:
	return CatalogoArmas.cadencia(_arma_id, attack_duration)


func _alcance_actual() -> float:
	return CatalogoArmas.alcance(_arma_id, alcance_ataque)


func _morir() -> void:
	murio.emit()
	puede_moverse = false
	atacando = false
	_hitbox.monitoring = false
	_guardar_arma()
	_sprite.modulate.a = 1.0
	_mejoras.reiniciar_vida()
	await get_tree().create_timer(0.6).timeout
	get_tree().reload_current_scene()


func _parpadear() -> void:
	var tween := create_tween()
	for i in 3:
		tween.tween_property(_sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(_sprite, "modulate:a", 1.0, 0.1)


func _on_invulnerabilidad_fin() -> void:
	_invulnerable = false
	_sprite.modulate.a = 1.0


func _on_attack_finished() -> void:
	atacando = false
	_hitbox.monitoring = false
	_guardar_arma()
	_play_idle()


func _offset_hitbox() -> Vector2:
	var dist := 8.0 * (_alcance_actual() / maxf(alcance_ataque, 1.0))
	match _dir_name(direccion):
		"derecha":
			return Vector2(dist, 0)
		"izquierda":
			return Vector2(-dist, 0)
		"arriba":
			return Vector2(0, -dist)
		_:
			return Vector2(0, dist)


func _play_idle() -> void:
	_sprite.play("idle-" + _dir_name(direccion))


func _play_walk(dir: Vector2) -> void:
	if absf(dir.x) >= absf(dir.y):
		_sprite.play("caminar-derecha" if dir.x > 0.0 else "caminar-izquierda")
	else:
		_sprite.play("caminar-abajo" if dir.y > 0.0 else "caminar-arriba")


func _dir_name(dir: Vector2) -> String:
	if absf(dir.x) >= absf(dir.y):
		return "derecha" if dir.x > 0.0 else "izquierda"
	return "abajo" if dir.y > 0.0 else "arriba"


func _on_dialogue_started(_resource: DialogueResource) -> void:
	puede_moverse = false


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	puede_moverse = true
