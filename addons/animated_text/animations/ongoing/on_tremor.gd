## Tremor — fast, tiny, uniform shake. Good for tension or a low rumble.
@tool
class_name OnTremor
extends OngoingAnimation

@export var amplitude: float = 0.6
@export var speed: float = 40.0

func _init() -> void:
	resource_name = "OnTremor"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	mod.offset.x += sin(time * speed + idx * 1.3) * amplitude
	mod.offset.y += cos(time * speed * 1.1 + idx * 2.1) * amplitude
