extends Area2D

## Zona que dispara una transición de escena al entrar el personaje.

@export_file("*.tscn") var escena_destino: String = ""
@export var punto_entrada: StringName = &""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("personaje"):
		return
	Transicion.cambiar_escena(escena_destino, punto_entrada)
