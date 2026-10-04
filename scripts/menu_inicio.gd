extends Control

## Menú de inicio: permite comenzar una partida nueva (reinicia inventario,
## monedero, mejoras y equipo) o salir del juego.

const MonederoTipo = preload("res://scripts/monedero.gd")
const MejorasTipo = preload("res://scripts/mejoras.gd")
const InventarioTipo = preload("res://scripts/inventario.gd")
const EquipoTipo = preload("res://scripts/equipo.gd")

const ESCENA_INICIAL: String = "res://scenes/bosque/bosque.tscn"
const PUNTO_ENTRADA: StringName = &"PuntosEntrada/DesdeMenu"

@onready var _boton_jugar: Button = %BotonJugar
@onready var _boton_salir: Button = %BotonSalir


func _ready() -> void:
	_boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	_boton_salir.pressed.connect(_on_boton_salir_pressed)
	_boton_jugar.grab_focus()


func _on_boton_jugar_pressed() -> void:
	var monedero := get_node("/root/Monedero") as MonederoTipo
	var mejoras := get_node("/root/Mejoras") as MejorasTipo
	var inventario := get_node("/root/Inventario") as InventarioTipo
	var equipo := get_node("/root/Equipo") as EquipoTipo
	monedero.reiniciar()
	mejoras.reiniciar()
	inventario.reiniciar()
	equipo.reiniciar()
	Transicion.cambiar_escena(ESCENA_INICIAL, PUNTO_ENTRADA)


func _on_boton_salir_pressed() -> void:
	get_tree().quit()
