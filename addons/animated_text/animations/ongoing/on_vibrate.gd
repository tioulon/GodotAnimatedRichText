## Vibrate — fast single-axis buzz (e.g. vertical only), uniform across glyphs.
## Distinct from OnTremor (omni-directional) and OnShake (random sampling).
@tool
class_name OnVibrate
extends OngoingAnimation

enum Axis { VERTICAL, HORIZONTAL }
@export var axis: Axis = Axis.VERTICAL
@export var amplitude: float = 1.2
@export var speed: float = 50.0
@export var char_phase: float = 1.0     ## phase spread per char (0 = all together)

func _init() -> void:
	resource_name = "OnVibrate"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var v := sin(time * speed + idx * char_phase) * amplitude
	if axis == Axis.VERTICAL:
		mod.offset.y += v
	else:
		mod.offset.x += v
