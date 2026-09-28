extends Node

## Autoload de mejoras permanentes: guarda los corazones máximos extra y la
## vida actual, y los mantiene entre escenarios. Es global y en memoria
## (no se guarda en disco).

signal cambiado(vida_maxima: int)

const VIDA_BASE: int = 3

var corazones_extra: int = 0
var vida_actual: int = -1


func vida_maxima() -> int:
	return VIDA_BASE + corazones_extra


func vida_guardada() -> int:
	if vida_actual < 0:
		return vida_maxima()
	return clampi(vida_actual, 0, vida_maxima())


func establecer_vida(cantidad: int) -> void:
	vida_actual = clampi(cantidad, 0, vida_maxima())


func reiniciar_vida() -> void:
	vida_actual = vida_maxima()


func agregar_corazon() -> void:
	corazones_extra += 1
	if vida_actual >= 0:
		vida_actual = mini(vida_actual + 1, vida_maxima())
	cambiado.emit(vida_maxima())


func reiniciar() -> void:
	corazones_extra = 0
	vida_actual = -1
	cambiado.emit(vida_maxima())
