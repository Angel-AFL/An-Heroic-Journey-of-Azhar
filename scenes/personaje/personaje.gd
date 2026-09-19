extends CharacterBody2D

@export var speed: float = 130.0
@export var attack_duration: float = 0.3

var puede_moverse: bool = true
var atacando: bool = false
var direccion: Vector2 = Vector2.DOWN

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _attack_timer: Timer = $AttackTimer


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_attack_timer.wait_time = attack_duration
	_attack_timer.timeout.connect(_on_attack_finished)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


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


func _on_attack_finished() -> void:
	atacando = false
	_play_idle()


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
