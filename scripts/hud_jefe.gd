extends Control

## Barra de vida del jefe: aparece cuando un jefe se registra y muestra su
## nombre y vida restante. Se oculta al morir el jefe.

const MARGEN: float = 4.0

var _jefe: Node = null

@onready var _fondo: ColorRect = $Fondo
@onready var _relleno: ColorRect = $Relleno
@onready var _nombre: Label = $Nombre


func _ready() -> void:
	hide()


func mostrar(jefe: Node) -> void:
	if not is_instance_valid(jefe):
		return
	_jefe = jefe
	if not jefe.vida_cambiada.is_connected(_on_vida_cambiada):
		jefe.vida_cambiada.connect(_on_vida_cambiada)
	_nombre.text = str(jefe.nombre)
	_actualizar(jefe.vida, jefe.vida_maxima)
	show()


func ocultar() -> void:
	hide()
	_jefe = null


func _on_vida_cambiada(vida_actual: int, vida_maxima: int) -> void:
	_actualizar(vida_actual, vida_maxima)


func _actualizar(vida_actual: int, vida_maxima: int) -> void:
	var ratio := 0.0
	if vida_maxima > 0:
		ratio = clampf(float(vida_actual) / float(vida_maxima), 0.0, 1.0)
	_relleno.size.x = maxf((_fondo.size.x - MARGEN * 2.0) * ratio, 0.0)
