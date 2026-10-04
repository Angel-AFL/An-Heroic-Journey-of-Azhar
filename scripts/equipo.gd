extends Node

## Autoload del equipo: guarda el arma equipada y la conserva entre
## escenarios. Es global y en memoria (no se guarda en disco).

signal arma_cambiada(id: StringName)

var _arma: StringName = &""


## Id del arma equipada (vacío si el Personaje va con los puños).
func arma_equipada() -> StringName:
	return _arma


## Indica si el arma indicada es la equipada.
func esta_equipada(id: StringName) -> bool:
	return _arma == id


## Equipa un arma y avisa del cambio.
func equipar(id: StringName) -> void:
	if id == &"" or _arma == id:
		return
	_arma = id
	arma_cambiada.emit(id)


## Desequipa el arma actual (vuelve a los puños).
func desequipar() -> void:
	if _arma == &"":
		return
	_arma = &""
	arma_cambiada.emit(&"")


## Deja el equipo como al empezar una partida nueva.
func reiniciar() -> void:
	_arma = &""
	arma_cambiada.emit(&"")
