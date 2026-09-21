extends "res://scripts/npc_dialogo.gd"

## Comerciante: además de dialogar, vende corazones máximos permanentes a
## cambio de monedas. Expone sus métodos al diálogo con el alias "Comerciante".

const MonederoTipo = preload("res://scripts/monedero.gd")
const MejorasTipo = preload("res://scripts/mejoras.gd")

@export var precios: Array[int] = [10, 30, 50]


func _ready() -> void:
	super._ready()
	DialogueManager.register_state_context("Comerciante", self)


func _exit_tree() -> void:
	DialogueManager.unregister_state_context("Comerciante")


func al_maximo() -> bool:
	return _mejoras().corazones_extra >= precios.size()


func precio_actual() -> int:
	if al_maximo():
		return -1
	return precios[_mejoras().corazones_extra]


func puede_comprar() -> bool:
	return not al_maximo() and _monedero().total >= precio_actual()


func comprar_corazon() -> bool:
	if al_maximo():
		return false
	if not _monedero().gastar(precio_actual()):
		return false
	_mejoras().agregar_corazon()
	return true


func _monedero() -> MonederoTipo:
	return get_node("/root/Monedero") as MonederoTipo


func _mejoras() -> MejorasTipo:
	return get_node("/root/Mejoras") as MejorasTipo
