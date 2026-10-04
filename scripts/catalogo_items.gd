extends RefCounted

## Catálogo de objetos del inventario: id -> metadatos (nombre, icono,
## descripción). Se accede con preload desde los scripts que lo necesiten:
##   const CatalogoItems = preload("res://scripts/catalogo_items.gd")
##   CatalogoItems.ITEMS  /  CatalogoItems.obtener(&"pocion_vida")

const ITEMS := {
	&"pocion_vida": {
		"nombre": "Poción de vida",
		"icono": preload("res://sprites/Items/Pociones/PocionVida.png"),
		"descripcion": "Restaura un poco de vida.",
		"tipo": "consumible",
		"curacion": 1,
	},
	&"pocion_mana": {
		"nombre": "Poción de maná",
		"icono": preload("res://sprites/Items/Pociones/PocionMana.png"),
		"descripcion": "Recupera energía mágica.",
		"tipo": "material",
	},
	&"espada": {
		"nombre": "Espada oxidada",
		"icono": preload("res://sprites/Items/Armas/Espada.png"),
		"descripcion": "Un arma vieja pero afilada.",
		"tipo": "arma",
		"max": 1,
	},
	&"scroll_fuego": {
		"nombre": "Pergamino de fuego",
		"icono": preload("res://sprites/Items/Pergaminos/ScrollFuego.png"),
		"descripcion": "Contiene un hechizo de fuego.",
		"tipo": "material",
	},
	&"llave_dorada": {
		"nombre": "Llave dorada",
		"icono": preload("res://sprites/Items/Tesoros/LlaveDorada.png"),
		"descripcion": "Abre algo importante.",
		"tipo": "material",
	},
	&"miel": {
		"nombre": "Tarro de miel",
		"icono": preload("res://sprites/Items/Ingredientes/Miel.png"),
		"descripcion": "Dulce y nutritiva.",
		"tipo": "material",
	},
}


## Devuelve los metadatos de un objeto (vacío si no está en el catálogo).
static func obtener(id: StringName) -> Dictionary:
	return ITEMS.get(id, {})


## Cantidad máxima del objeto (-1 si no tiene límite, es decir, apilable).
static func maximo(id: StringName) -> int:
	return int(obtener(id).get("max", -1))


## Nombre legible del objeto (el id si no está en el catálogo).
static func nombre(id: StringName) -> String:
	return str(obtener(id).get("nombre", id))


## Icono del objeto (null si no está en el catálogo de items).
static func icono(id: StringName) -> Texture2D:
	return obtener(id).get("icono", null)
