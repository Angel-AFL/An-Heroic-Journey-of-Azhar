extends Control

## Cinemática de introducción: muestra la historia de Azhar en varias diapositivas
## automáticas, con retratos y tintes. También se reutiliza para la victoria.
## Se puede avanzar
## con E/clic y saltar con Esc o con el botón.

const FONDO: Texture2D = preload("res://sprites/UI/menu-inicio.jpg")
const MUSICA: AudioStream = preload("res://audio/menu-inicio.mp3")
const RETRATO_NARRADOR: Texture2D = preload("res://sprites/UI/Retratos/Narrador.svg")
const RETRATO_ANCIANO: Texture2D = preload("res://sprites/Personajes/NPC/OldMan2/Faceset.png")
const RETRATO_AZHAR: Texture2D = preload("res://sprites/Personajes/GreenNinja/_Faceset.png")
const ENEMIGO_SLIME: Texture2D = preload("res://sprites/Personajes/Enemigos/Enemigo_4.png")
const ENEMIGO_CACTUS: Texture2D = preload("res://sprites/Personajes/Enemigos/Enemigo_1.png")
const ENEMIGO_HIELO: Texture2D = preload("res://sprites/Personajes/Enemigos/Enemigo_3.png")
const PIEDRA_BOSQUE: Texture2D = preload("res://sprites/Items/Tesoros/PiedraBosque.svg")
const PIEDRA_DESIERTO: Texture2D = preload("res://sprites/Items/Tesoros/PiedraDesierto.svg")
const PIEDRA_NIEVE: Texture2D = preload("res://sprites/Items/Tesoros/PiedraNieve.svg")

const ESCENA_BOSQUE: String = "res://scenes/bosque/bosque.tscn"
const ESCENA_MENU: String = "res://scenes/ui/menu_inicio.tscn"
const PUNTO_BOSQUE: StringName = &"PuntosEntrada/DesdeMenu"

const TINTE_PAZ: Color = Color(0.03, 0.07, 0.04, 0.32)
const TINTE_AMENAZA: Color = Color(0.14, 0.02, 0.04, 0.48)
const TINTE_ANCIANO: Color = Color(0.09, 0.06, 0.03, 0.38)
const TINTE_HEROE: Color = Color(0.12, 0.09, 0.03, 0.34)
const TINTE_FINAL: Color = Color(0.02, 0.02, 0.03, 0.5)
const TINTE_VICTORIA: Color = Color(0.12, 0.10, 0.03, 0.28)
const TINTE_AMANECER: Color = Color(0.16, 0.12, 0.04, 0.24)
const TINTE_RELIQUIAS: Color = Color(0.14, 0.11, 0.04, 0.32)
const TINTE_FIN: Color = Color(0.04, 0.04, 0.03, 0.45)

@export var es_victoria: bool = false

var _diapositivas: Array = []

var _diapositivas_intro: Array = [
	{
		"personaje": "Narrador",
		"retrato": RETRATO_NARRADOR,
		"texto": "En un rincón del mundo, más allá de los caminos conocidos, se alzaba la villa de Azhar.",
		"tinte": TINTE_PAZ,
		"siluetas": false,
	},
	{
		"personaje": "Narrador",
		"retrato": RETRATO_NARRADOR,
		"texto": "Durante generaciones, sus gentes vivieron en paz, protegidas por el bosque.",
		"tinte": TINTE_PAZ,
		"siluetas": false,
	},
	{
		"personaje": "Narrador",
		"retrato": RETRATO_NARRADOR,
		"texto": "Pero las amenazas de fuera cruzaron los caminos. Criaturas de barro, espinas y fuego helado arrasaron los biomas.",
		"tinte": TINTE_AMENAZA,
		"siluetas": true,
	},
	{
		"personaje": "Narrador",
		"retrato": RETRATO_NARRADOR,
		"texto": "Y bajo la tierra, algo antiguo comenzó a despertar.",
		"tinte": TINTE_AMENAZA,
		"siluetas": true,
	},
	{
		"personaje": "Anciano",
		"retrato": RETRATO_ANCIANO,
		"texto": "Azhar... eres un héroe. El pueblo ha confiado siempre en ti.",
		"tinte": TINTE_ANCIANO,
		"siluetas": false,
	},
	{
		"personaje": "Anciano",
		"retrato": RETRATO_ANCIANO,
		"texto": "Recorre el bosque, el desierto y la nieve. Encuentra las tres piedras ancestrales y detén a quienes amenazan nuestra tierra.",
		"tinte": TINTE_ANCIANO,
		"siluetas": false,
	},
	{
		"personaje": "Azhar",
		"retrato": RETRATO_AZHAR,
		"texto": "No temáis. Mientras yo respire, la villa no caerá.",
		"tinte": TINTE_HEROE,
		"siluetas": false,
	},
	{
		"personaje": "Narrador",
		"retrato": RETRATO_NARRADOR,
		"texto": "Al final del camino, una sombra antigua aguarda. Tu viaje comienza ahora.",
		"tinte": TINTE_FINAL,
		"siluetas": false,
	},
]

var _diapositivas_victoria: Array = [
	{
		"personaje": "Narrador",
		"retrato": RETRATO_NARRADOR,
		"texto": "La sombra del Eclipse se disipó. El último guardián cayó.",
		"tinte": TINTE_VICTORIA,
		"siluetas": true,
	},
	{
		"personaje": "Narrador",
		"retrato": RETRATO_NARRADOR,
		"texto": "El bosque volvió a respirar. El desierto calló. La nieve dejó de aullar.",
		"tinte": TINTE_AMANECER,
		"siluetas": true,
	},
	{
		"personaje": "Anciano",
		"retrato": RETRATO_ANCIANO,
		"texto": "Azhar... lo has logrado. El pueblo está a salvo.",
		"tinte": TINTE_ANCIANO,
		"siluetas": false,
	},
	{
		"personaje": "Azhar",
		"retrato": RETRATO_AZHAR,
		"texto": "La villa está a salvo. Pero el mundo es grande... y siempre habrá a quién proteger.",
		"tinte": TINTE_HEROE,
		"siluetas": false,
	},
	{
		"personaje": "Narrador",
		"retrato": RETRATO_NARRADOR,
		"texto": "Ahora que Azhar acabó con el mal, el pueblo está a salvo.",
		"tinte": TINTE_RELIQUIAS,
		"siluetas": true,
	},
	{
		"personaje": "Narrador",
		"retrato": RETRATO_NARRADOR,
		"texto": "Su leyenda apenas comienza.",
		"tinte": TINTE_FIN,
		"siluetas": false,
	},
]

var _fondo: TextureRect
var _tinte: ColorRect
var _siluetas: Control
var _panel: PanelContainer
var _nombre: Label
var _retrato: TextureRect
var _texto: Label
var _boton_saltar: Button
var _negro: ColorRect
var _musica: AudioStreamPlayer
var _timer_avance: Timer
var _tween_silueta: Tween

var _indice: int = -1
var _typing: bool = false
var _progreso: float = 0.0
var _terminado: bool = false
var _listo: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_diapositivas = _diapositivas_victoria if es_victoria else _diapositivas_intro
	_construir()
	_iniciar()


func _construir() -> void:
	_fondo = TextureRect.new()
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_fondo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var recorte := AtlasTexture.new()
	recorte.atlas = FONDO
	recorte.region = Rect2(0, 0, 900, 1000)
	_fondo.texture = recorte
	_fondo.scale = Vector2(1.06, 1.06)
	add_child(_fondo)

	_tinte = ColorRect.new()
	_tinte.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tinte.color = TINTE_VICTORIA if es_victoria else TINTE_PAZ
	_tinte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tinte)

	_siluetas = _crear_reliquias() if es_victoria else _crear_siluetas()
	add_child(_siluetas)

	_crear_barras()

	_panel = _crear_panel()

	_boton_saltar = _crear_boton_saltar()
	add_child(_boton_saltar)

	_negro = ColorRect.new()
	_negro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_negro.color = Color(0, 0, 0, 0)
	_negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_negro.z_index = 100
	add_child(_negro)

	_musica = AudioStreamPlayer.new()
	_musica.stream = MUSICA
	_musica.bus = &"Musica"
	_musica.volume_db = -6.0
	_musica.autoplay = true
	add_child(_musica)

	_timer_avance = Timer.new()
	_timer_avance.one_shot = true
	_timer_avance.timeout.connect(_on_timer_avance_timeout)
	add_child(_timer_avance)


func _crear_siluetas() -> Control:
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.modulate.a = 0.0
	capa.visible = false
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 44)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(fila)
	for textura in [ENEMIGO_SLIME, ENEMIGO_CACTUS, ENEMIGO_HIELO]:
		var atlas := AtlasTexture.new()
		atlas.atlas = textura
		atlas.region = Rect2(0, 0, 16, 16)
		var icono := TextureRect.new()
		icono.texture = atlas
		icono.custom_minimum_size = Vector2(88, 88)
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icono.modulate = Color(0.3, 0.08, 0.32, 0.95)
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(icono)
	return capa


func _crear_reliquias() -> Control:
	var capa := Control.new()
	capa.set_anchors_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.modulate.a = 0.0
	capa.visible = false
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(centro)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 44)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.add_child(fila)
	for textura in [PIEDRA_BOSQUE, PIEDRA_DESIERTO, PIEDRA_NIEVE]:
		var icono := TextureRect.new()
		icono.texture = textura
		icono.custom_minimum_size = Vector2(72, 72)
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icono.modulate = Color(1.0, 0.95, 0.75, 0.95)
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(icono)
	return capa


func _crear_barras() -> void:
	var arriba := ColorRect.new()
	arriba.color = Color.BLACK
	arriba.anchor_right = 1.0
	arriba.offset_bottom = 26.0
	arriba.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arriba)
	var abajo := ColorRect.new()
	abajo.color = Color.BLACK
	abajo.anchor_top = 1.0
	abajo.anchor_bottom = 1.0
	abajo.anchor_right = 1.0
	abajo.offset_top = -26.0
	abajo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(abajo)


func _crear_panel() -> PanelContainer:
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_FULL_RECT)
	margen.add_theme_constant_override("margin_left", 40)
	margen.add_theme_constant_override("margin_right", 40)
	margen.add_theme_constant_override("margin_bottom", 20)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margen)

	var columna := VBoxContainer.new()
	columna.set_anchors_preset(Control.PRESET_FULL_RECT)
	columna.alignment = BoxContainer.ALIGNMENT_END
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margen.add_child(columna)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _estilo_panel())
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	columna.add_child(panel)

	var caja := HBoxContainer.new()
	caja.add_theme_constant_override("separation", 12)
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(caja)

	var marco := PanelContainer.new()
	marco.custom_minimum_size = Vector2(48, 48)
	marco.add_theme_stylebox_override("panel", _estilo_retrato())
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(marco)

	_retrato = TextureRect.new()
	_retrato.custom_minimum_size = Vector2(38, 38)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marco.add_child(_retrato)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_child(textos)

	_nombre = Label.new()
	_nombre.add_theme_font_size_override("font_size", 18)
	_nombre.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.add_child(_nombre)

	_texto = Label.new()
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.add_theme_font_size_override("font_size", 16)
	_texto.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	_texto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.add_child(_texto)
	return panel


func _crear_boton_saltar() -> Button:
	var boton := Button.new()
	boton.text = "Saltar (Esc)"
	boton.focus_mode = Control.FOCUS_NONE
	boton.anchor_left = 1.0
	boton.anchor_right = 1.0
	boton.offset_left = -170.0
	boton.offset_top = 20.0
	boton.offset_right = -20.0
	boton.offset_bottom = 54.0
	boton.add_theme_font_size_override("font_size", 14)
	boton.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	boton.add_theme_stylebox_override("normal", _estilo_boton(0))
	boton.add_theme_stylebox_override("hover", _estilo_boton(1))
	boton.add_theme_stylebox_override("pressed", _estilo_boton(2))
	boton.pressed.connect(_on_saltar)
	return boton


func _estilo_panel() -> StyleBoxTexture:
	var estilo := StyleBoxTexture.new()
	estilo.texture = preload("res://sprites/UI/Dialog/DialogueBoxSimple.png")
	estilo.texture_margin_left = 6.0
	estilo.texture_margin_top = 6.0
	estilo.texture_margin_right = 6.0
	estilo.texture_margin_bottom = 6.0
	estilo.content_margin_left = 18.0
	estilo.content_margin_top = 12.0
	estilo.content_margin_right = 18.0
	estilo.content_margin_bottom = 12.0
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
	estilo.content_margin_left = 12.0
	estilo.content_margin_top = 4.0
	estilo.content_margin_right = 12.0
	estilo.content_margin_bottom = 4.0
	if estado == 1:
		estilo.modulate_color = Color(1.0, 0.95, 0.6, 1.0)
	elif estado == 2:
		estilo.modulate_color = Color(0.85, 0.75, 0.5, 1.0)
	return estilo


func _iniciar() -> void:
	await get_tree().create_timer(0.6).timeout
	_fondo.pivot_offset = _fondo.size * 0.5
	var zoom := create_tween()
	zoom.tween_property(_fondo, "scale", Vector2(1.14, 1.14), 38.0).set_trans(Tween.TRANS_SINE)
	_listo = true
	_avanzar()


func _process(delta: float) -> void:
	if not _typing:
		return
	_progreso += delta * 70.0
	_texto.visible_characters = mini(int(_progreso), _texto.text.length())
	if _texto.visible_characters >= _texto.text.length():
		_typing = false
		_iniciar_espera()


func _avanzar() -> void:
	_timer_avance.stop()
	_indice += 1
	if _indice >= _diapositivas.size():
		_finalizar(false)
		return
	_mostrar_diapositiva(_diapositivas[_indice])


func _mostrar_diapositiva(datos: Dictionary) -> void:
	_nombre.text = str(datos["personaje"])
	_retrato.texture = datos["retrato"] as Texture2D
	_texto.text = str(datos["texto"])
	_texto.visible_characters = 0
	_typing = true
	_progreso = 0.0
	_panel.modulate.a = 0.0
	var aparicion := create_tween()
	aparicion.tween_property(_panel, "modulate:a", 1.0, 0.3)
	var color_tinte: Color = datos["tinte"]
	var tinte := create_tween()
	tinte.tween_property(_tinte, "color", color_tinte, 0.7)
	_actualizar_siluetas(bool(datos["siluetas"]))


func _actualizar_siluetas(mostrar: bool) -> void:
	if _tween_silueta != null and _tween_silueta.is_valid():
		_tween_silueta.kill()
	_siluetas.visible = true
	_tween_silueta = create_tween()
	_tween_silueta.tween_property(_siluetas, "modulate:a", 1.0 if mostrar else 0.0, 0.45)
	if not mostrar:
		_tween_silueta.tween_callback(_ocultar_siluetas)


func _ocultar_siluetas() -> void:
	_siluetas.visible = false


func _iniciar_espera() -> void:
	var duracion := maxf(2.0, _texto.text.length() * 0.022)
	_timer_avance.start(duracion)


func _on_timer_avance_timeout() -> void:
	_avanzar()


func _unhandled_input(event: InputEvent) -> void:
	if _terminado or not _listo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finalizar(true)
		return
	var clic: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if event.is_action_pressed("interactuar") or clic:
		get_viewport().set_input_as_handled()
		_avanzar_manual()


func _avanzar_manual() -> void:
	if _terminado:
		return
	if _typing:
		_typing = false
		_texto.visible_characters = _texto.text.length()
		_iniciar_espera()
		return
	_avanzar()


func _on_saltar() -> void:
	if not _listo:
		return
	_finalizar(true)


func _finalizar(saltar: bool) -> void:
	if _terminado:
		return
	_terminado = true
	_typing = false
	_timer_avance.stop()
	_boton_saltar.hide()
	var duracion := 0.45 if saltar else 0.8
	var fundido := create_tween()
	fundido.set_parallel(true)
	fundido.tween_property(_negro, "color:a", 1.0, duracion)
	fundido.tween_property(_musica, "volume_db", -40.0, duracion)
	await fundido.finished
	if es_victoria:
		Transicion.cambiar_escena(ESCENA_MENU)
	else:
		Transicion.cambiar_escena(ESCENA_BOSQUE, PUNTO_BOSQUE)
