extends RefCounted

## Catálogo de armas: id -> estadísticas de combate (tipo, daño, cadencia,
## alcance, sprite en mano y proyectil para las armas a distancia). Complementa
## a catalogo_items.gd, que define nombre/icono/descripción para el inventario.
##   const CatalogoArmas = preload("res://scripts/catalogo_armas.gd")
##   CatalogoArmas.obtener(&"espada")  /  CatalogoArmas.dano(&"mazo")

const ARMAS := {
	&"hueso": {
		"tipo": "melee",
		"dano": 1,
		"cadencia": 0.22,
		"alcance": 22.0,
		"sprite_mano": preload("res://sprites/Items/Armas/Hueso.png"),
	},
	&"espada": {
		"tipo": "melee",
		"dano": 2,
		"cadencia": 0.30,
		"alcance": 24.0,
		"sprite_mano": preload("res://sprites/Items/Armas/Espada.png"),
	},
	&"tridente": {
		"tipo": "melee",
		"dano": 3,
		"cadencia": 0.40,
		"alcance": 34.0,
		"sprite_mano": preload("res://sprites/Items/Armas/Tridente.png"),
	},
	&"mazo": {
		"tipo": "melee",
		"dano": 4,
		"cadencia": 0.55,
		"alcance": 26.0,
		"sprite_mano": preload("res://sprites/Items/Armas/Mazo.png"),
	},
	&"arco": {
		"tipo": "rango",
		"dano": 2,
		"cadencia": 0.45,
		"alcance": 0.0,
		"sprite_mano": preload("res://sprites/Items/Armas/Arco.png"),
		"proyectil": preload("res://sprites/Items/Tesoros/Kunai.png"),
		"velocidad_proyectil": 260.0,
	},
	&"vara": {
		"tipo": "rango",
		"dano": 2,
		"cadencia": 0.40,
		"alcance": 0.0,
		"sprite_mano": preload("res://sprites/Items/Armas/Vara.png"),
		"proyectil": preload("res://sprites/Proyectiles/PicoHielo.png"),
		"velocidad_proyectil": 220.0,
	},
	&"baston": {
		"tipo": "rango",
		"dano": 3,
		"cadencia": 0.50,
		"alcance": 0.0,
		"sprite_mano": preload("res://sprites/Items/Armas/Baston.png"),
		"proyectil": preload("res://sprites/Proyectiles/BolaEnergia.png"),
		"velocidad_proyectil": 240.0,
	},
	&"libro": {
		"tipo": "rango",
		"dano": 3,
		"cadencia": 0.60,
		"alcance": 0.0,
		"sprite_mano": preload("res://sprites/Items/Armas/Libro.png"),
		"proyectil": preload("res://sprites/Proyectiles/BolaFuego.png"),
		"velocidad_proyectil": 200.0,
	},
}


## Devuelve las estadísticas de un arma (vacío si no está en el catálogo).
static func obtener(id: StringName) -> Dictionary:
	return ARMAS.get(id, {})


## Tipo de arma: "melee" (por defecto) o "rango".
static func tipo(id: StringName) -> String:
	return str(obtener(id).get("tipo", "melee"))


## Daño del arma (dano_base si no está en el catálogo, p. ej. los puños).
static func dano(id: StringName, dano_base: int) -> int:
	return int(obtener(id).get("dano", dano_base))


## Cadencia del arma en segundos (cadencia_base si no está en el catálogo).
static func cadencia(id: StringName, cadencia_base: float) -> float:
	return float(obtener(id).get("cadencia", cadencia_base))


## Alcance del arma en píxeles (alcance_base si no está en el catálogo).
static func alcance(id: StringName, alcance_base: float) -> float:
	return float(obtener(id).get("alcance", alcance_base))


## Textura del arma empuñada (null si no está en el catálogo).
static func sprite_mano(id: StringName) -> Texture2D:
	return obtener(id).get("sprite_mano", null)


## Textura del proyectil de un arma a distancia (null si no dispara).
static func proyectil(id: StringName) -> Texture2D:
	return obtener(id).get("proyectil", null)


## Velocidad del proyectil de un arma a distancia.
static func velocidad_proyectil(id: StringName) -> float:
	return float(obtener(id).get("velocidad_proyectil", 240.0))
