## Fade out — alpha 1 → 0.
@tool
class_name OutFade
extends OutAnimation

func _init() -> void:
	resource_name = "OutFade"
	easing = ATEasing.Type.IN_QUAD

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	mod.alpha = 1.0 - eased(t)
