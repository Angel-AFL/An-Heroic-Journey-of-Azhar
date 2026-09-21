extends Node

## Autoload del monedero: guarda el total de monedas y lo mantiene entre
## escenarios. Es global y en memoria (no se guarda en disco).

signal cambiado(total: int)

var total: int = 0


func agregar(cantidad: int = 1) -> void:
	if cantidad <= 0:
		return
	total += cantidad
	cambiado.emit(total)


func gastar(cantidad: int) -> bool:
	if cantidad <= 0:
		return true
	if total < cantidad:
		return false
	total -= cantidad
	cambiado.emit(total)
	return true


func reiniciar() -> void:
	total = 0
	cambiado.emit(total)
