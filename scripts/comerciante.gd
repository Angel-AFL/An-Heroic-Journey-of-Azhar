extends "res://scripts/npc_dialogo.gd"

## Comerciante: además de dialogar, vende corazones máximos permanentes y
## objetos a cambio de monedas. Expone sus métodos al diálogo con el alias "Comerciante".
const MonederoTipo = preload("res://scripts/monedero.gd")
const MejorasTipo = preload("res://scripts/mejoras.gd")
const InventarioTipo = preload("res://scripts/inventario.gd")
const EquipoTipo = preload("res://scripts/equipo.gd")
const CatalogoItems = preload("res://scripts/catalogo_items.gd")

@export var precios: Array[int] = [10, 30, 50]
@export var precios_items: Dictionary = {
	"pocion_vida": 15,
	"espada": 40,
}


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


func precio_item(id: String) -> int:
	return int(precios_items.get(id, -1))


func puede_comprar_item(id: String) -> bool:
	var precio := precio_item(id)
	return precio >= 0 and _monedero().total >= precio


func comprar_item(id: String) -> bool:
	var precio := precio_item(id)
	if precio < 0:
		return false
	var clave := StringName(id)
	if CatalogoItems.maximo(clave) == 1 and (_inventario().tiene(clave) or _equipo().esta_equipada(clave)):
		return false
	if not _monedero().gastar(precio):
		return false
	_inventario().agregar(clave)
	return true


func nombre_item(id: String) -> String:
	return CatalogoItems.nombre(StringName(id))


func _monedero() -> MonederoTipo:
	return get_node("/root/Monedero") as MonederoTipo


func _mejoras() -> MejorasTipo:
	return get_node("/root/Mejoras") as MejorasTipo


func _inventario() -> InventarioTipo:
	return get_node("/root/Inventario") as InventarioTipo


func _equipo() -> EquipoTipo:
	return get_node("/root/Equipo") as EquipoTipo
