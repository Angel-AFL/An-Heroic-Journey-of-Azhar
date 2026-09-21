extends Node

## Autoload de mejoras permanentes: guarda los corazones máximos extra y los
## mantiene entre escenarios. Es global y en memoria (no se guarda en disco).

signal cambiado(vida_maxima: int)

const VIDA_BASE: int = 3

var corazones_extra: int = 0


func vida_maxima() -> int:
	return VIDA_BASE + corazones_extra


func agregar_corazon() -> void:
	corazones_extra += 1
	cambiado.emit(vida_maxima())


func reiniciar() -> void:
	corazones_extra = 0
	cambiado.emit(vida_maxima())
