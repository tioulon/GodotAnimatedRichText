## Spin out — glyph rotates and shrinks away (mirror of InSpin).
@tool
class_name OutSpin
extends OutAnimation

@export var to_degrees: float = 180.0
@export var clockwise: bool = true
@export var to_scale: float = 0.0
@export var fade: bool = true

func _init() -> void:
	resource_name = "OutSpin"
	easing = ATEasing.Type.IN_BACK

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.rotation = deg_to_rad(to_degrees) * e * (1.0 if clockwise else -1.0)
	var s := lerpf(1.0, to_scale, e)
	mod.scale = Vector2(s, s)
	if fade:
		mod.alpha = 1.0 - sub(t, 0.5, 1.0)
