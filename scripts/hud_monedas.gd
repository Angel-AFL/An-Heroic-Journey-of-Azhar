extends HBoxContainer

## Contador de monedas del HUD: muestra el total del monedero global y lo
## actualiza cuando cambia. El total persiste entre escenarios.

const MonederoTipo = preload("res://scripts/monedero.gd")

@onready var _etiqueta: Label = $Etiqueta
@onready var _monedero: MonederoTipo = get_node("/root/Monedero") as MonederoTipo


func _ready() -> void:
	_monedero.cambiado.connect(_on_cambiado)
	_actualizar(_monedero.total)


func _on_cambiado(total: int) -> void:
	_actualizar(total)


func _actualizar(total: int) -> void:
	_etiqueta.text = str(total)
