extends Node2D

## Puerta ancestral del bosque: comprueba las tres piedras de los jefes y,
## si están todas, abre el paso al Santuario del Eclipse. Los mensajes usan
## el mismo balloon de diálogo que los NPCs.

const InventarioTipo = preload("res://scripts/inventario.gd")
const DIALOGO_PUERTA: DialogueResource = preload("res://dialogues/puerta_ancestral.dialogue")
const PIEDRAS: Array[StringName] = [
	&"piedra_bosque",
	&"piedra_desierto",
	&"piedra_nieve",
]

@export_file("*.tscn") var escena_destino: String = "res://scenes/santuario/santuario.tscn"
@export var punto_entrada: StringName = &"PuntosEntrada/DesdeBosque"

var _jugador_cerca: bool = false
var _abierta: bool = false
var _abriendo: bool = false
var _ocupado: bool = false

@onready var _visual: Node2D = $Visual
@onready var _etiqueta: Label = $Etiqueta
@onready var _zona_paso: Area2D = $ZonaPaso
@onready var _bloqueo: CollisionShape2D = $Bloqueo/CollisionShape2D
@onready var _engastes: Array = [
	$Visual/PiedraBosque,
	$Visual/PiedraDesierto,
	$Visual/PiedraNieve,
]


func _ready() -> void:
	$ZonaInteraccion.body_entered.connect(_on_zona_entered)
	$ZonaInteraccion.body_exited.connect(_on_zona_exited)
	_zona_paso.monitoring = false
	_etiqueta.visible = false
	for engaste in _engastes:
		engaste.modulate = Color(0.25, 0.24, 0.3, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if _abierta or _abriendo or _ocupado or not _jugador_cerca:
		return
	if not event.is_action_pressed("interactuar"):
		return
	get_viewport().set_input_as_handled()
	_ocupado = true
	_etiqueta.visible = false
	if _tiene_piedras():
		_abrir()
	else:
		_mostrar_cerrada()


func _tiene_piedras() -> bool:
	var inventario := get_node_or_null("/root/Inventario") as InventarioTipo
	if inventario == null:
		return false
	for piedra in PIEDRAS:
		if not inventario.tiene(piedra):
			return false
	return true


func _mostrar_cerrada() -> void:
	_sacudir()
	for engaste in _engastes:
		engaste.modulate = Color(0.8, 0.15, 0.15, 1.0)
	DialogueManager.show_dialogue_balloon(DIALOGO_PUERTA, "cerrada")
	await DialogueManager.dialogue_ended
	_apagar_engastes()
	_ocupado = false
	if _jugador_cerca and not _abierta:
		_etiqueta.visible = true


func _sacudir() -> void:
	var tween := create_tween()
	for i in 3:
		tween.tween_property(_visual, "position:x", 2.0, 0.045)
		tween.tween_property(_visual, "position:x", -2.0, 0.045)
	tween.tween_property(_visual, "position:x", 0.0, 0.045)


func _apagar_engastes() -> void:
	if _abierta:
		return
	for engaste in _engastes:
		engaste.modulate = Color(0.25, 0.24, 0.3, 1.0)


func _abrir() -> void:
	_abriendo = true
	_etiqueta.visible = false
	DialogueManager.show_dialogue_balloon(DIALOGO_PUERTA, "abierta")
	await DialogueManager.dialogue_ended

	var luces := create_tween()
	luces.set_parallel(true)
	for i in _engastes.size():
		var engaste: Sprite2D = _engastes[i]
		luces.tween_property(engaste, "modulate", Color.WHITE, 0.25).set_delay(0.18 * i)
		luces.tween_property(engaste, "scale", Vector2(0.7, 0.7), 0.15).set_delay(0.18 * i)
	await get_tree().create_timer(0.9).timeout

	var apertura := create_tween()
	apertura.set_parallel(true)
	apertura.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	apertura.tween_property($Visual/HojaIzquierda, "position:x", -24.0, 0.8)
	apertura.tween_property($Visual/HojaDerecha, "position:x", 24.0, 0.8)
	apertura.tween_property($Visual/HojaIzquierda, "modulate:a", 0.0, 0.8)
	apertura.tween_property($Visual/HojaDerecha, "modulate:a", 0.0, 0.8)
	await apertura.finished
	$Visual/HojaIzquierda.hide()
	$Visual/HojaDerecha.hide()

	_bloqueo.set_deferred("disabled", true)
	_zona_paso.set_deferred("monitoring", true)
	_abierta = true
	_abriendo = false
	_ocupado = false
	await get_tree().physics_frame
	for cuerpo in _zona_paso.get_overlapping_bodies():
		if cuerpo.is_in_group("personaje"):
			Transicion.cambiar_escena(escena_destino, punto_entrada)
			return


func _on_zona_entered(body: Node2D) -> void:
	if not body.is_in_group("personaje"):
		return
	_jugador_cerca = true
	if not _abierta and not _abriendo and not _ocupado:
		_etiqueta.visible = true


func _on_zona_exited(body: Node2D) -> void:
	if not body.is_in_group("personaje"):
		return
	_jugador_cerca = false
	_etiqueta.visible = false
