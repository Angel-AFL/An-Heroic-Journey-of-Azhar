extends CanvasLayer

## Pantalla de muerte: pausa el juego, muestra "HAS MUERTO" y permite al jugador
## continuar en el bosque o volver al menú de inicio.

const MejorasTipo = preload("res://scripts/mejoras.gd")
const ESCENA_REAPARICION: String = "res://scenes/bosque/bosque.tscn"
const PUNTO_REAPARICION: StringName = &"PuntosEntrada/DesdeMenu"
const ESCENA_MENU: String = "res://scenes/ui/menu_inicio.tscn"

const COLOR_TITULO: Color = Color(0.45, 0.08, 0.08, 1.0)
const COLOR_TEXTO: Color = Color(0.18, 0.12, 0.12, 1.0)
const COLOR_VELO: Color = Color(0.0, 0.0, 0.0, 0.86)
const COLOR_TINTE: Color = Color(0.2, 0.02, 0.02, 0.32)

var _raiz: Control
var _velo: ColorRect
var _tinte: ColorRect
var _panel: PanelContainer
var _boton_seguir: Button
var _boton_salir: Button
var _tween: Tween
var _accionando: bool = false


func _ready() -> void:
	layer = 200
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir()
	hide()


func _construir() -> void:
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.modulate.a = 0.0
	add_child(_raiz)

	_velo = ColorRect.new()
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.color = COLOR_VELO
	_velo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(_velo)

	_tinte = ColorRect.new()
	_tinte.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tinte.color = COLOR_TINTE
	_tinte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_tinte)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.add_child(centro)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", _estilo_panel())
	_panel.custom_minimum_size = Vector2(430, 0)
	centro.add_child(_panel)

	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 14)
	_panel.add_child(caja)

	var cabecera := HBoxContainer.new()
	cabecera.add_theme_constant_override("separation", 14)
	caja.add_child(cabecera)

	var marco_retrato := PanelContainer.new()
	marco_retrato.custom_minimum_size = Vector2(64, 64)
	marco_retrato.add_theme_stylebox_override("panel", _estilo_retrato())
	cabecera.add_child(marco_retrato)

	var retrato := TextureRect.new()
	retrato.texture = preload("res://sprites/Personajes/GreenNinja/Dead.png")
	retrato.custom_minimum_size = Vector2(48, 48)
	retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marco_retrato.add_child(retrato)

	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 4)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(textos)

	var titulo := Label.new()
	titulo.text = "HAS MUERTO"
	titulo.add_theme_font_size_override("font_size", 30)
	titulo.add_theme_color_override("font_color", COLOR_TITULO)
	textos.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "La oscuridad te ha alcanzado."
	subtitulo.add_theme_font_size_override("font_size", 15)
	subtitulo.add_theme_color_override("font_color", COLOR_TEXTO)
	textos.add_child(subtitulo)

	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 12)
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	caja.add_child(botones)

	_boton_seguir = _crear_boton("Seguir jugando")
	_boton_seguir.pressed.connect(_on_seguir_jugando)
	botones.add_child(_boton_seguir)

	_boton_salir = _crear_boton("Salir")
	_boton_salir.pressed.connect(_on_salir)
	botones.add_child(_boton_salir)


func _crear_boton(texto: String) -> Button:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(190, 38)
	boton.focus_mode = Control.FOCUS_ALL
	boton.add_theme_font_size_override("font_size", 18)
	boton.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	boton.add_theme_color_override("font_hover_color", Color(0, 0, 0, 1))
	boton.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 1))
	boton.add_theme_color_override("font_focus_color", Color(0, 0, 0, 1))
	boton.add_theme_stylebox_override("normal", _estilo_boton(0))
	boton.add_theme_stylebox_override("hover", _estilo_boton(1))
	boton.add_theme_stylebox_override("pressed", _estilo_boton(2))
	boton.add_theme_stylebox_override("focus", _estilo_boton(1))
	return boton


func _estilo_panel() -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = preload("res://sprites/UI/Dialog/DialogueBoxSimple.png")
	estilo.texture_margin_left = 6.0
	estilo.texture_margin_top = 6.0
	estilo.texture_margin_right = 6.0
	estilo.texture_margin_bottom = 6.0
	estilo.content_margin_left = 20.0
	estilo.content_margin_top = 16.0
	estilo.content_margin_right = 20.0
	estilo.content_margin_bottom = 16.0
	return estilo


func _estilo_retrato() -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = preload("res://sprites/UI/Dialog/FacesetBox.png")
	estilo.texture_margin_left = 5.0
	estilo.texture_margin_top = 5.0
	estilo.texture_margin_right = 5.0
	estilo.texture_margin_bottom = 5.0
	estilo.content_margin_left = 5.0
	estilo.content_margin_top = 5.0
	estilo.content_margin_right = 5.0
	estilo.content_margin_bottom = 5.0
	return estilo


func _estilo_boton(estado: int) -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = preload("res://sprites/UI/Dialog/ChoiceBox.png")
	estilo.texture_margin_left = 6.0
	estilo.texture_margin_top = 4.0
	estilo.texture_margin_right = 6.0
	estilo.texture_margin_bottom = 4.0
	estilo.content_margin_left = 14.0
	estilo.content_margin_top = 6.0
	estilo.content_margin_right = 14.0
	estilo.content_margin_bottom = 6.0
	if estado == 1:
		estilo.modulate_color = Color(1.0, 0.95, 0.6, 1.0)
	elif estado == 2:
		estilo.modulate_color = Color(0.85, 0.75, 0.5, 1.0)
	return estilo


## Muestra la pantalla de muerte y pausa el juego.
func mostrar() -> void:
	if visible:
		return
	_accionando = false
	show()
	get_tree().paused = true
	_raiz.modulate.a = 0.0
	_boton_seguir.grab_focus()
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(_raiz, "modulate:a", 1.0, 0.55)
	_tween.parallel().tween_property(_tinte, "color:a", 0.4, 0.55)
	_tween.tween_property(_tinte, "color:a", 0.28, 0.6)


func _on_seguir_jugando() -> void:
	if _accionando:
		return
	_accionando = true
	get_tree().paused = false
	hide()
	var mejoras := get_node("/root/Mejoras") as MejorasTipo
	if mejoras != null:
		mejoras.reiniciar_vida()
	Transicion.cambiar_escena(ESCENA_REAPARICION, PUNTO_REAPARICION)


func _on_salir() -> void:
	if _accionando:
		return
	_accionando = true
	get_tree().paused = false
	hide()
	Transicion.cambiar_escena(ESCENA_MENU)
