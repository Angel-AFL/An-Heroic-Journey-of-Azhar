extends Control

## HUD de corazones: dibuja la vida del Personaje y la actualiza al recibir daño.

const ESCALA: float = 0.4
const SEPARACION: float = 18.0
const MARGEN: Vector2 = Vector2(8, 8)
const PUNTOS_CORAZON: int = 32
const COLOR_LLENO: Color = Color("#e23b3b")
const COLOR_VACIO: Color = Color("#3a2b2b")
const COLOR_BORDE: Color = Color("#1a1010")

var _vida: int = 0
var _vida_maxima: int = 0
var _jugador: Node = null


func _ready() -> void:
	_jugador = get_tree().get_first_node_in_group("personaje")
	if is_instance_valid(_jugador):
		_vida = _jugador.vida
		_vida_maxima = _jugador.vida_maxima
		_jugador.vida_cambiada.connect(_on_vida_cambiada)
	queue_redraw()


func _on_vida_cambiada(vida_actual: int, vida_maxima: int) -> void:
	_vida = vida_actual
	_vida_maxima = vida_maxima
	queue_redraw()


func _draw() -> void:
	for i in _vida_maxima:
		var centro := MARGEN + Vector2(SEPARACION * float(i) + 8.0, 8.0)
		var lleno := i < _vida
		draw_colored_polygon(_puntos_corazon(centro, ESCALA * 1.18), COLOR_BORDE)
		draw_colored_polygon(_puntos_corazon(centro, ESCALA), COLOR_LLENO if lleno else COLOR_VACIO)


func _puntos_corazon(centro: Vector2, escala: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in PUNTOS_CORAZON:
		var t := TAU * float(i) / float(PUNTOS_CORAZON)
		var x := 16.0 * pow(sin(t), 3.0)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		puntos.append(centro + Vector2(x, -y) * escala)
	return puntos
