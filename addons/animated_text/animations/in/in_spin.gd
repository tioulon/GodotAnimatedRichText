## Spin — glyph rotates and scales into place.
@tool
class_name InSpin
extends InAnimation

@export var from_degrees: float = 180.0
@export var clockwise: bool = true
@export var from_scale: float = 0.0
@export var fade: bool = true

func _init() -> void:
	resource_name = "InSpin"
	easing = ATEasing.Type.OUT_CUBIC

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	var ang := deg_to_rad(from_degrees) * (1.0 - e)
	mod.rotation = ang * (-1.0 if clockwise else 1.0)
	var s := lerpf(from_scale, 1.0, e)
	mod.scale = Vector2(s, s)
	if fade:
		mod.alpha = sub(t, 0.0, 0.5)
