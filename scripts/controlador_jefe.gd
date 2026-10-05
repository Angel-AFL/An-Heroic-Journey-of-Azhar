extends Node2D

## Espera a que mueran todos los enemigos normales del nivel y entonces hace
## aparecer al jefe de bioma en su propia posición. Colocá este nodo donde
## quieras que aparezca el jefe y asignale `escena_jefe`.

@export var escena_jefe: PackedScene
@export var nodo_enemigos: NodePath = ^"../Enemigos"

var _restantes: int = 0
var _jefe_aparecido: bool = false


func _ready() -> void:
	var raiz := get_node_or_null(nodo_enemigos)
	if raiz == null:
		raiz = get_parent().get_node_or_null("Enemigos")
	if raiz == null:
		return
	for hijo in raiz.get_children():
		if not is_instance_valid(hijo) or hijo.is_in_group("jefe"):
			continue
		if hijo.has_signal("murio"):
			_restantes += 1
			hijo.murio.connect(_on_enemigo_muerto)
	if _restantes == 0:
		_aparecer_jefe()


func _on_enemigo_muerto() -> void:
	if _jefe_aparecido:
		return
	_restantes -= 1
	if _restantes <= 0:
		_aparecer_jefe()


func _aparecer_jefe() -> void:
	if _jefe_aparecido or escena_jefe == null:
		return
	_jefe_aparecido = true
	var escena := get_tree().current_scene
	if escena == null:
		return
	var jefe := escena_jefe.instantiate() as Node2D
	escena.add_child(jefe)
	jefe.global_position = global_position
