extends CharacterBody2D

## Personaje jugable: movimiento direccional, ataque cuerpo a cuerpo con
## hitbox frontal, vida con invulnerabilidad temporal y muerte.

signal vida_cambiada(vida_actual: int, vida_maxima: int)
signal murio

@export var speed: float = 130.0
@export var attack_duration: float = 0.3
@export var vida_maxima: int = 3
@export var dano_ataque: int = 1
@export var invulnerabilidad: float = 0.8

var puede_moverse: bool = true
var atacando: bool = false
var direccion: Vector2 = Vector2.DOWN
var vida: int = 0
var _invulnerable: bool = false
var _golpeados: Array = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _attack_timer: Timer = $AttackTimer
@onready var _hitbox: Area2D = $Hitbox
@onready var _inv_timer: Timer = $InvulnerabilidadTimer
@onready var _espada: Sprite2D = $Espada


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	vida = vida_maxima
	_attack_timer.wait_time = attack_duration
	_attack_timer.timeout.connect(_on_attack_finished)
	_inv_timer.one_shot = true
	_inv_timer.wait_time = invulnerabilidad
	_inv_timer.timeout.connect(_on_invulnerabilidad_fin)
	_hitbox.body_entered.connect(_on_hitbox_body_entered)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
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
		_attack_timer.start()
		_activar_hitbox()
		_empunar_espada()


func _activar_hitbox() -> void:
	_golpeados.clear()
	_hitbox.position = _offset_hitbox()
	_hitbox.monitoring = true
	await get_tree().physics_frame
	if atacando:
		_golpear_en_hitbox()


func _empunar_espada() -> void:
	_espada.visible = true
	match _dir_name(direccion):
		"derecha":
			_espada.position = Vector2(9, 4)
			_espada.rotation = PI / 2.0
		"izquierda":
			_espada.position = Vector2(-12, 5)
			_espada.rotation = -PI / 2.0
		"arriba":
			_espada.position = Vector2(0, -9)
			_espada.rotation = 0.0
		_:
			_espada.position = Vector2(0, 9)
			_espada.rotation = PI


func _guardar_espada() -> void:
	_espada.visible = false


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
	_golpeados.append(cuerpo)
	cuerpo.recibir_dano(dano_ataque)


func recibir_dano(cantidad: int) -> void:
	if cantidad <= 0 or _invulnerable or vida <= 0:
		return
	vida = maxi(vida - cantidad, 0)
	vida_cambiada.emit(vida, vida_maxima)
	_invulnerable = true
	_inv_timer.start()
	_parpadear()
	if vida <= 0:
		_morir()


func _morir() -> void:
	murio.emit()
	puede_moverse = false
	atacando = false
	_hitbox.monitoring = false
	_guardar_espada()
	_sprite.modulate.a = 1.0
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
	_guardar_espada()
	_play_idle()


func _offset_hitbox() -> Vector2:
	match _dir_name(direccion):
		"derecha":
			return Vector2(12, 0)
		"izquierda":
			return Vector2(-12, 0)
		"arriba":
			return Vector2(0, -12)
		_:
			return Vector2(0, 12)


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
