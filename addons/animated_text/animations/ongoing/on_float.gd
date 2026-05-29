## Float — whole text drifts up/down together (no per-glyph phase).
@tool
class_name OnFloat
extends OngoingAnimation

@export var amplitude: float = 2.0
@export var speed: float = 1.2
@export var sway: bool = false
@export var sway_amplitude: float = 1.0
@export var sway_speed: float = 0.7

func _init() -> void:
	resource_name = "OnFloat"

func apply(mod: CharMod, time: float, _idx: int, _total: int) -> void:
	mod.offset.y += sin(time * speed * PI) * amplitude
	if sway:
		mod.offset.x += sin(time * sway_speed * PI) * sway_amplitude
