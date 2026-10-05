extends "res://scripts/comerciante.gd"

## Herrero (Rodrigo): además de dialogar, vende armas y objetos a cambio de
## monedas. Expone sus métodos al diálogo con el alias "Herrero".

@export var precios_armas: Dictionary = {
	"hueso": 15,
	"espada": 40,
	"kunai": 60,
	"vara": 65,
	"tridente": 70,
	"baston": 80,
	"mazo": 90,
	"libro": 100,
}


func _alias_contexto() -> String:
	return "Herrero"


## Precio de un arma (cae a los objetos del comerciante base si no es un arma).
func precio_item(id: String) -> int:
	if precios_armas.has(id):
		return int(precios_armas[id])
	return super.precio_item(id)
