extends HBoxContainer

## Hotbar del inventario: un slot fijo a la izquierda para el arma equipada
## (tecla 0) y casillas dinámicas que se llenan con los objetos obtenidos
## (siempre visibles, se llenan en orden de obtención). Las teclas 1-5 seleccionan, F usa/equipa y 0 el arma.

const InventarioTipo = preload("res://scripts/inventario.gd")
const CatalogoItems = preload("res://scripts/catalogo_items.gd")
const EquipoTipo = preload("res://scripts/equipo.gd")
const SonidoTipo = preload("res://scripts/sonido.gd")
const SONIDO_EQUIPAR: AudioStream = preload("res://audio/moneda.wav")

const MAX_SLOTS: int = 5
const COLOR_BORDE: Color = Color(0.0784314, 0.105882, 0.105882, 1.0)
const COLOR_BORDE_ACTIVO: Color = Color(1.0, 0.827451, 0.419608, 1.0)
const COLOR_BORDE_EQUIPO: Color = Color(0.439216, 0.541176, 0.639216, 1.0)
const COLOR_BORDE_EQUIPO_ACTIVO: Color = Color(0.611765, 0.803922, 1.0, 1.0)
const COLOR_FONDO: Color = Color(0.101961, 0.0784314, 0.0784314, 0.75)
const COLOR_FONDO_ACTIVO: Color = Color(0.16, 0.12, 0.12, 0.9)
const COLOR_FONDO_VACIO: Color = Color(0.101961, 0.0784314, 0.0784314, 0.35)
const COLOR_BORDE_VACIO: Color = Color(0.0784314, 0.105882, 0.105882, 0.5)
const COLOR_CUENTA: Color = Color(1.0, 0.85, 0.4, 1.0)

var _paneles: Array[PanelContainer] = []
var _iconos: Array[TextureRect] = []
var _numeros: Array[Label] = []
var _cuentas: Array[Label] = []
var _panel_equipo: PanelContainer
var _icono_equipo: TextureRect
var _id_activo: StringName = &""
var _equipo_seleccionado: bool = false
var _inventario: InventarioTipo
var _equipo: EquipoTipo
var _sonido: SonidoTipo


func _ready() -> void:
	_inventario = get_node("/root/Inventario") as InventarioTipo
	_equipo = get_node("/root/Equipo") as EquipoTipo
	_sonido = get_node("/root/Sonido") as SonidoTipo
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)
	_construir()
	_inventario.cambiado.connect(_on_cambiado)
	_equipo.arma_cambiada.connect(_on_arma_cambiada)
	_refrescar()


func _unhandled_input(event: InputEvent) -> void:
	for i in MAX_SLOTS:
		if event.is_action_pressed("slot_%d" % (i + 1)):
			_seleccionar_indice(i)
			return

	if event.is_action_pressed("slot_equipo"):
		_seleccionar_equipo()
		return

	if event.is_action_pressed("usar"):
		if _usar():
			get_viewport().set_input_as_handled()


func _seleccionar_indice(indice: int) -> void:
	var ids := _ids_visibles()
	if indice < 0 or indice >= ids.size() or not _puede_actuar():
		return
	get_viewport().set_input_as_handled()
	_equipo_seleccionado = false
	_id_activo = ids[indice]
	_refrescar()


func _seleccionar_equipo() -> void:
	if _equipo.arma_equipada() == &"" or not _puede_actuar():
		return
	get_viewport().set_input_as_handled()
	_equipo_seleccionado = true
	_id_activo = &""
	_refrescar()


func _usar() -> bool:
	if not _puede_actuar():
		return false
	if _equipo_seleccionado:
		return _desequipar()
	if _id_activo == &"" or not _inventario.tiene(_id_activo):
		return false
	match str(CatalogoItems.obtener(_id_activo).get("tipo", "material")):
		"consumible":
			return _usar_consumible(_id_activo)
		"arma":
			return _usar_arma(_id_activo)
	return false


func _usar_consumible(id: StringName) -> bool:
	var jugador := get_tree().get_first_node_in_group("personaje")
	if not is_instance_valid(jugador) or not jugador.has_method("curar"):
		return false
	var curacion := int(CatalogoItems.obtener(id).get("curacion", 0))
	if not jugador.curar(curacion):
		return false
	_inventario.quitar(id, 1)
	return true


func _usar_arma(id: StringName) -> bool:
	if _equipo.esta_equipada(id):
		return _desequipar()
	if not _inventario.tiene(id):
		return false
	_inventario.quitar(id, 1)
	_equipo.equipar(id)
	_sonido.reproducir(SONIDO_EQUIPAR)
	_equipo_seleccionado = true
	_id_activo = &""
	_refrescar()
	return true


func _desequipar() -> bool:
	var id := _equipo.arma_equipada()
	if id == &"":
		return false
	_equipo.desequipar()
	_inventario.agregar(id, 1)
	_sonido.reproducir(SONIDO_EQUIPAR)
	_equipo_seleccionado = false
	_id_activo = id
	_refrescar()
	return true


func _puede_actuar() -> bool:
	var jugador := get_tree().get_first_node_in_group("personaje")
	if is_instance_valid(jugador):
		var puede: Variant = jugador.get("puede_moverse")
		if puede is bool and not puede:
			return false
	return true


func _ids_visibles() -> Array:
	var ids := _inventario.items().keys()
	if ids.size() > MAX_SLOTS:
		ids = ids.slice(0, MAX_SLOTS)
	return ids


func _construir() -> void:
	_panel_equipo = _crear_slot_equipo()
	add_child(_panel_equipo)

	var separador := Control.new()
	separador.custom_minimum_size = Vector2(14, 0)
	separador.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(separador)

	for i in MAX_SLOTS:
		add_child(_crear_slot_item())


func _crear_slot_equipo() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(44, 44)
	panel.add_theme_stylebox_override("panel", _estilo_slot(false, true))

	var capa := Control.new()
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(capa)

	_icono_equipo = TextureRect.new()
	_icono_equipo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icono_equipo.offset_left = 7.0
	_icono_equipo.offset_top = 7.0
	_icono_equipo.offset_right = -7.0
	_icono_equipo.offset_bottom = -7.0
	_icono_equipo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icono_equipo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icono_equipo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_icono_equipo)

	var numero := _crear_numero("0")
	capa.add_child(numero)
	return panel


func _crear_slot_item() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(44, 44)
	panel.add_theme_stylebox_override("panel", _estilo_slot(false))

	var capa := Control.new()
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(capa)

	var icono := TextureRect.new()
	icono.set_anchors_preset(Control.PRESET_FULL_RECT)
	icono.offset_left = 7.0
	icono.offset_top = 7.0
	icono.offset_right = -7.0
	icono.offset_bottom = -7.0
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(icono)

	var numero := _crear_numero("")
	capa.add_child(numero)

	var cuenta := Label.new()
	cuenta.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	cuenta.offset_left = -20.0
	cuenta.offset_top = -17.0
	cuenta.offset_right = -3.0
	cuenta.offset_bottom = -1.0
	cuenta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cuenta.add_theme_font_size_override("font_size", 11)
	cuenta.add_theme_color_override("font_color", COLOR_CUENTA)
	cuenta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	cuenta.add_theme_constant_override("outline_size", 3)
	cuenta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(cuenta)

	_paneles.append(panel)
	_iconos.append(icono)
	_numeros.append(numero)
	_cuentas.append(cuenta)
	return panel


func _crear_numero(texto: String) -> Label:
	var numero := Label.new()
	numero.text = texto
	numero.position = Vector2(3.0, 1.0)
	numero.add_theme_font_size_override("font_size", 10)
	numero.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	numero.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	numero.add_theme_constant_override("outline_size", 3)
	numero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return numero


func _refrescar() -> void:
	var ids := _ids_visibles()
	if _id_activo != &"" and not ids.has(_id_activo):
		_id_activo = &""

	for i in MAX_SLOTS:
		_paneles[i].visible = true
		_numeros[i].text = str(i + 1)
		if i < ids.size():
			var id: StringName = ids[i]
			var cantidad := _inventario.cantidad(id)
			_iconos[i].texture = CatalogoItems.icono(id)
			_cuentas[i].text = ("x%d" % cantidad) if cantidad > 1 else ""
			_paneles[i].add_theme_stylebox_override("panel", _estilo_slot(not _equipo_seleccionado and id == _id_activo))
		else:
			_iconos[i].texture = null
			_cuentas[i].text = ""
			_paneles[i].add_theme_stylebox_override("panel", _estilo_slot(false, false, true))

	var arma := _equipo.arma_equipada()
	_icono_equipo.texture = CatalogoItems.icono(arma) if arma != &"" else null
	_icono_equipo.modulate.a = 1.0 if arma != &"" else 0.3
	_panel_equipo.add_theme_stylebox_override("panel", _estilo_slot(_equipo_seleccionado, true))


func _estilo_slot(activo: bool, es_equipo: bool = false, vacio: bool = false) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	if vacio:
		estilo.bg_color = COLOR_FONDO_VACIO
		estilo.border_color = COLOR_BORDE_VACIO
	else:
		estilo.bg_color = COLOR_FONDO_ACTIVO if activo else COLOR_FONDO
		if es_equipo:
			estilo.border_color = COLOR_BORDE_EQUIPO_ACTIVO if activo else COLOR_BORDE_EQUIPO
		else:
			estilo.border_color = COLOR_BORDE_ACTIVO if activo else COLOR_BORDE
	estilo.set_border_width_all(3 if activo else 2)
	estilo.set_corner_radius_all(4)
	return estilo


func _on_cambiado(_id: StringName, _cantidad: int) -> void:
	_refrescar()


func _on_arma_cambiada(_id: StringName) -> void:
	_refrescar()
