## Stand Up — chars rotate up from lying flat, pivoting at their base.
@tool
class_name InStandUp
extends InAnimation

@export var from_degrees: float = -90.0
@export var fade: bool = true

func _init() -> void:
	resource_name = "InStandUp"
	easing = ATEasing.Type.OUT_BACK

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.pivot = Vector2(0.5, 1.0)   # pivot at the bottom
	mod.rotation = deg_to_rad(from_degrees) * (1.0 - e)
	if fade:
		mod.alpha = sub(t, 0.0, 0.4)
