extends Node

## Autoload de sonido: reproduce efectos por un pool de AudioStreamPlayer
## en el bus "SFX", de modo que el sonido sigue sonando aunque el nodo que
## lo dispara (p. ej. una moneda) se libere inmediatamente.

const CANTIDAD_REPRODUCTORES: int = 8
const BUS_SFX: String = "SFX"

var _reproductores: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in CANTIDAD_REPRODUCTORES:
		var reproductor := AudioStreamPlayer.new()
		reproductor.bus = BUS_SFX
		add_child(reproductor)
		_reproductores.append(reproductor)


func reproducir(stream: AudioStream, volumen_db: float = 0.0) -> void:
	if stream == null:
		return
	var reproductor := _buscar_libre()
	reproductor.stream = stream
	reproductor.volume_db = volumen_db
	reproductor.play()


func _buscar_libre() -> AudioStreamPlayer:
	for reproductor in _reproductores:
		if not reproductor.playing:
			return reproductor
	return _reproductores[0]
