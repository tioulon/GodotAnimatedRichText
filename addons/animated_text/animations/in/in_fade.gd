## Fade — alpha 0 → 1.
@tool
class_name InFade
extends InAnimation

func _init() -> void:
	resource_name = "InFade"
	easing = ATEasing.Type.OUT_QUAD

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	mod.alpha = eased(t)
