## Unfold — chars expand vertically from a thin line, like a banner unrolling.
@tool
class_name InUnfold
extends InAnimation

@export var from_scale_y: float = 0.05
@export var overshoot: bool = true
@export var fade: bool = true

func _init() -> void:
	resource_name = "InUnfold"
	easing = ATEasing.Type.OUT_BACK if overshoot else ATEasing.Type.OUT_CUBIC

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.scale = Vector2(1.0, lerpf(from_scale_y, 1.0, e))
	if fade:
		mod.alpha = sub(t, 0.0, 0.4)
