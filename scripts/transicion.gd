extends Node

## Autoload de transiciones de escena con fundido a negro.
## Uso: Transicion.cambiar_escena("res://scenes/villa/villa.tscn", &"PuntosEntrada/DesdeBosque")

const DURACION_FADE: float = 0.35

var _capa: CanvasLayer
var _velo: ColorRect
var _en_transicion: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_capa = CanvasLayer.new()
	_capa.layer = 128
	add_child(_capa)

	_velo = ColorRect.new()
	_velo.color = Color(0.0, 0.0, 0.0, 0.0)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_capa.add_child(_velo)


## Funde a negro, cambia de escena y funde de vuelta.
## punto_entrada es la ruta (relativa a la raíz de la escena destino) del
## Node2D donde debe aparecer el Personaje.
func cambiar_escena(ruta_destino: String, punto_entrada: StringName = &"") -> void:
	if _en_transicion:
		return
	if ruta_destino.is_empty() or not ResourceLoader.exists(ruta_destino):
		push_warning("Transicion: escena destino no encontrada: %s" % ruta_destino)
		return

	_en_transicion = true

	await _fundir(1.0)
	get_tree().change_scene_to_file(ruta_destino)
	await _esperar_escena(ruta_destino)
	_colocar_personaje(punto_entrada)
	await _fundir(0.0)

	_en_transicion = false


func _fundir(alpha: float) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_velo, "color:a", alpha, DURACION_FADE)
	await tween.finished


func _esperar_escena(ruta_destino: String) -> void:
	for _i in range(20):
		await get_tree().process_frame
		var actual := get_tree().current_scene
		if actual != null and actual.scene_file_path == ruta_destino:
			return


func _colocar_personaje(punto_entrada: StringName) -> void:
	if punto_entrada.is_empty():
		return

	var escena := get_tree().current_scene
	if escena == null:
		return

	var marcador := escena.get_node_or_null(NodePath(punto_entrada))
	if marcador is not Node2D:
		push_warning("Transicion: marcador de entrada no encontrado: %s" % punto_entrada)
		return

	var personaje := escena.get_node_or_null("Personaje")
	if personaje is Node2D:
		personaje.position = (marcador as Node2D).position
