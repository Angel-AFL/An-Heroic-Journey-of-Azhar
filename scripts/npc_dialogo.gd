extends Node2D

## NPC que inicia un diálogo al pulsar "interactuar" cuando el personaje está cerca.

@export var dialogo: DialogueResource
@export var cue_inicio: String = "start"

var _jugador_cerca: bool = false
var _dialogo_activo: bool = false


func _ready() -> void:
	var zona := $ZonaInteraccion
	zona.body_entered.connect(_on_zona_body_entered)
	zona.body_exited.connect(_on_zona_body_exited)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _unhandled_input(event: InputEvent) -> void:
	if _dialogo_activo or not _jugador_cerca:
		return
	if not event.is_action_pressed("interactuar"):
		return
	if dialogo == null:
		push_warning("NPC %s: no tiene un DialogueResource asignado." % name)
		return
	get_viewport().set_input_as_handled()
	_dialogo_activo = true
	DialogueManager.show_dialogue_balloon(dialogo, cue_inicio)


func _on_zona_body_entered(body: Node2D) -> void:
	if body.is_in_group("personaje"):
		_jugador_cerca = true


func _on_zona_body_exited(body: Node2D) -> void:
	if body.is_in_group("personaje"):
		_jugador_cerca = false


func _on_dialogue_started(_resource: DialogueResource) -> void:
	_dialogo_activo = true


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	_dialogo_activo = false
