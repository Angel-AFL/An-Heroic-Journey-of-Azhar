extends Node

## Modo desarrollador: atajos para testear sin jugar la partida completa.
## El farmeo de monedas está activo por defecto y solo funciona en builds de
## debug. Para desactivarlo, cambia FARMEO_MONEDAS_ACTIVO a false.

const FARMEO_MONEDAS_ACTIVO: bool = true
const MONEDAS_POR_PULSACION: int = 100
const ACCION_FARMEO: StringName = &"dev_farmear_monedas"

const MonederoTipo = preload("res://scripts/monedero.gd")
const SonidoTipo = preload("res://scripts/sonido.gd")
const SONIDO_MONEDA: AudioStream = preload("res://audio/moneda.wav")

var _monedero: MonederoTipo
var _sonido: SonidoTipo


func _ready() -> void:
	if not FARMEO_MONEDAS_ACTIVO or not OS.is_debug_build():
		set_process_unhandled_input(false)
		return
	_monedero = get_node("/root/Monedero") as MonederoTipo
	_sonido = get_node("/root/Sonido") as SonidoTipo


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(ACCION_FARMEO):
		return
	if get_tree().paused:
		return
	if get_tree().get_first_node_in_group("personaje") == null:
		return
	get_viewport().set_input_as_handled()
	_monedero.agregar(MONEDAS_POR_PULSACION)
	_sonido.reproducir(SONIDO_MONEDA)
