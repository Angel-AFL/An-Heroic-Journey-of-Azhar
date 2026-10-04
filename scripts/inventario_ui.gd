extends CanvasLayer

## Panel de inventario: se abre/cierra con la acción "inventario" (I o Tab) o
## Esc, pausa el juego y muestra los objetos con su cantidad. Vive dentro del
## HUD, que se instancia en cada nivel (uno por escena).

const InventarioTipo = preload("res://scripts/inventario.gd")
const CatalogoItems = preload("res://scripts/catalogo_items.gd")

const COLUMNAS: int = 4
const COLOR_VELO: Color = Color(0, 0, 0, 0.55)
const COLOR_PANEL: Color = Color(0.12, 0.09, 0.09, 0.96)
const COLOR_BORDE: Color = Color(0.0784314, 0.105882, 0.105882, 1.0)
const COLOR_TEXTO: Color = Color(0.94902, 0.917647, 0.945098, 1.0)
const COLOR_PISTA: Color = Color(0.75, 0.72, 0.72, 1.0)

var _abierto: bool = false
var _rejilla: GridContainer
var _vacio: Label
var _inventario: InventarioTipo


func _ready() -> void:
	layer = 64
	process_mode = Node.PROCESS_MODE_ALWAYS
	_inventario = get_node("/root/Inventario") as InventarioTipo
	_construir()
	_inventario.cambiado.connect(_on_inventario_cambiado)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _abierto:
		if event.is_action_pressed("inventario") or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_cerrar()
		return

	if not event.is_action_pressed("inventario"):
		return
	if not _puede_abrir():
		return
	get_viewport().set_input_as_handled()
	_abrir()


func _puede_abrir() -> bool:
	var jugador := get_tree().get_first_node_in_group("personaje")
	if not is_instance_valid(jugador):
		return true
	var puede: Variant = jugador.get("puede_moverse")
	if puede is bool and not puede:
		return false
	return true


func _abrir() -> void:
	_abierto = true
	_refrescar()
	visible = true
	get_tree().paused = true


func _cerrar() -> void:
	_abierto = false
	visible = false
	get_tree().paused = false


func _on_inventario_cambiado(_id: StringName, _cantidad: int) -> void:
	if _abierto:
		_refrescar()


func _construir() -> void:
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(raiz)

	var velo := ColorRect.new()
	velo.color = COLOR_VELO
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	velo.mouse_filter = Control.MOUSE_FILTER_STOP
	raiz.add_child(velo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(centro)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	centro.add_child(panel)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	panel.add_child(caja)

	var titulo := Label.new()
	titulo.text = "Inventario"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 22)
	titulo.add_theme_color_override("font_color", COLOR_TEXTO)
	caja.add_child(titulo)

	_vacio = Label.new()
	_vacio.text = "No llevas ningún objeto."
	_vacio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vacio.add_theme_color_override("font_color", COLOR_TEXTO)
	caja.add_child(_vacio)

	_rejilla = GridContainer.new()
	_rejilla.columns = COLUMNAS
	_rejilla.add_theme_constant_override("h_separation", 10)
	_rejilla.add_theme_constant_override("v_separation", 10)
	caja.add_child(_rejilla)

	var pista := Label.new()
	pista.text = "I / Esc para cerrar"
	pista.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pista.add_theme_font_size_override("font_size", 12)
	pista.add_theme_color_override("font_color", COLOR_PISTA)
	caja.add_child(pista)


func _estilo_panel() -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = COLOR_PANEL
	estilo.border_color = COLOR_BORDE
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(6)
	estilo.content_margin_left = 18
	estilo.content_margin_right = 18
	estilo.content_margin_top = 12
	estilo.content_margin_bottom = 12
	return estilo


func _refrescar() -> void:
	for hijo in _rejilla.get_children():
		hijo.queue_free()
	var items := _inventario.items()
	_vacio.visible = items.is_empty()
	for id in items:
		_rejilla.add_child(_crear_slot(id, int(items[id])))


func _crear_slot(id: StringName, cantidad: int) -> Control:
	var slot := VBoxContainer.new()
	slot.custom_minimum_size = Vector2(64, 0)
	slot.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_theme_constant_override("separation", 2)

	var icono := TextureRect.new()
	icono.texture = CatalogoItems.icono(id)
	icono.custom_minimum_size = Vector2(40, 40)
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(icono)

	var nombre := Label.new()
	nombre.text = CatalogoItems.nombre(id)
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nombre.custom_minimum_size = Vector2(64, 0)
	nombre.add_theme_font_size_override("font_size", 11)
	nombre.add_theme_color_override("font_color", COLOR_TEXTO)
	slot.add_child(nombre)

	var cuenta := Label.new()
	cuenta.text = "x%d" % cantidad
	cuenta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cuenta.add_theme_font_size_override("font_size", 12)
	cuenta.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	slot.add_child(cuenta)

	return slot
