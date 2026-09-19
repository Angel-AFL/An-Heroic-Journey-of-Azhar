extends CharacterBody2D

@export var speed: float = 130.0

var puede_moverse: bool = true

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _physics_process(_delta: float) -> void:
	if not puede_moverse:
		velocity = Vector2.ZERO
		_sprite.play("idle")
		move_and_slide()
		return

	var direction := Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")

	if direction != Vector2.ZERO:
		velocity = direction * speed
		_play_walk(direction)
	else:
		velocity = Vector2.ZERO
		_sprite.play("idle")

	move_and_slide()


func _play_walk(direction: Vector2) -> void:
	if absf(direction.x) >= absf(direction.y):
		_sprite.play("caminar-derecha" if direction.x > 0.0 else "caminar-izquierda")
	else:
		_sprite.play("caminar-abajo" if direction.y > 0.0 else "caminar-arriba")


func _on_dialogue_started(_resource: DialogueResource) -> void:
	puede_moverse = false


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	puede_moverse = true
