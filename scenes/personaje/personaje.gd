extends CharacterBody2D

@export var speed: float = 130.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")

	if direction != Vector2.ZERO:
		velocity = direction * speed
		_play_walk(direction)
	else:
		velocity = Vector2.ZERO
		_sprite.play("dile")

	move_and_slide()


func _play_walk(direction: Vector2) -> void:
	if absf(direction.x) >= absf(direction.y):
		_sprite.play("caminar-derecha" if direction.x > 0.0 else "caminar-izquierda")
	else:
		_sprite.play("caminar-abajo" if direction.y > 0.0 else "caminar-arriba")
