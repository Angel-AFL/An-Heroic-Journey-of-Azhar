extends Node

## Autoload del inventario: guarda la cantidad de cada objeto por id y la
## mantiene entre escenarios. Es global y en memoria (no se guarda en disco).

const CatalogoItems = preload("res://scripts/catalogo_items.gd")

signal cambiado(id: StringName, cantidad: int)

var _items: Dictionary = {}


## Suma una cantidad al objeto indicado y avisa del cambio. Respeta el
## máximo del catálogo (p. ej. las armas son objetos únicos).
func agregar(id: StringName, unidades: int = 1) -> void:
	if id == &"" or unidades <= 0:
		return
	var actual := int(_items.get(id, 0))
	var nuevo := actual + unidades
	var maximo := CatalogoItems.maximo(id)
	if maximo >= 0:
		nuevo = mini(nuevo, maximo)
	if nuevo == actual:
		return
	_items[id] = nuevo
	cambiado.emit(id, nuevo)


## Resta una cantidad si hay suficiente. Devuelve true si se pudo quitar.
func quitar(id: StringName, unidades: int = 1) -> bool:
	if unidades <= 0:
		return true
	var actual := int(_items.get(id, 0))
	if actual < unidades:
		return false
	var restante := actual - unidades
	if restante == 0:
		_items.erase(id)
	else:
		_items[id] = restante
	cambiado.emit(id, restante)
	return true


## Indica si el objeto está en el inventario (al menos una unidad).
func tiene(id: StringName) -> bool:
	return _items.has(id)


## Cantidad actual del objeto (0 si no lo tiene).
func cantidad(id: StringName) -> int:
	return int(_items.get(id, 0))


## Copia del inventario actual (id -> cantidad, en orden de obtención).
func items() -> Dictionary:
	return _items.duplicate()


## Vacía el inventario.
func vaciar() -> void:
	for id in _items.keys():
		_items.erase(id)
		cambiado.emit(id, 0)


## Deja el inventario como al empezar una partida nueva (vacío).
func reiniciar() -> void:
	vaciar()
