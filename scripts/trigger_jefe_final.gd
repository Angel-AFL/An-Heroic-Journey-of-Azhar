extends Area2D

## Activa la aparición del Guardián del Eclipse cuando el jugador entra en la
## plaza central del Santuario. Primero muestra su diálogo, luego lo invoca y
## finalmente lanza la cinemática de victoria cuando cae.

const DIALOGO_GUARDIAN: DialogueResource = preload("res://dialogues/guardian_eclipse.dialogue")
const LUZ: Texture2D = preload("res://sprites/Mapa/LuzSuave.svg")
const ESCENA_VICTORIA: String = "res://scenes/ui/cinematica_victoria.tscn"
const ESCENA_SANTUARIO: String = "res://scenes/santuario/santuario.tscn"

@export var escena_jefe: PackedScene
@export var punto_aparicion: NodePath = ^"../PuntosJefe"

var _activado: bool = false
var _victoria_iniciada: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _activado or not body.is_in_group("personaje"):
		return
	if escena_jefe == null:
		return
	_activado = true
	DialogueManager.show_dialogue_balloon(DIALOGO_GUARDIAN, "despertar")
	await DialogueManager.dialogue_ended
	var escena := get_tree().current_scene
	if escena == null:
		return
	var marcador := get_node_or_null(punto_aparicion) as Node2D
	var posicion := marcador.position if marcador != null else global_position
	var jefe := escena_jefe.instantiate() as Node2D
	jefe.position = posicion
	jefe.connect("murio", _on_jefe_muerto)
	escena.call_deferred("add_child", jefe)
	_destello(posicion)


func _on_jefe_muerto() -> void:
	if _victoria_iniciada:
		return
	_victoria_iniciada = true
	await get_tree().create_timer(1.2).timeout
	var escena := get_tree().current_scene
	if escena == null or escena.scene_file_path != ESCENA_SANTUARIO:
		return
	if get_tree().paused:
		return
	var jugador := get_tree().get_first_node_in_group("personaje")
	if jugador == null or jugador.vida <= 0:
		return
	Transicion.cambiar_escena(ESCENA_VICTORIA)


func _destello(posicion: Vector2) -> void:
	var escena := get_tree().current_scene
	if escena == null:
		return
	var luz := Sprite2D.new()
	luz.texture = LUZ
	luz.position = posicion
	luz.scale = Vector2.ONE * 0.8
	luz.modulate = Color(0.55, 0.3, 0.9, 0.75)
	luz.z_index = 2
	escena.add_child(luz)
	var tween := luz.create_tween()
	tween.set_parallel(true)
	tween.tween_property(luz, "scale", Vector2.ONE * 3.0, 0.7)
	tween.tween_property(luz, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(luz.queue_free)
