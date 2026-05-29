## Bounce out — glyph launches up then fades.
@tool
class_name OutBounce
extends OutAnimation

@export var distance: float = 14.0
@export var fade: bool = true

func _init() -> void:
	resource_name = "OutBounce"
	easing = ATEasing.Type.IN_QUAD

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.offset.y = -e * distance
	if fade:
		mod.alpha = 1.0 - sub(t, 0.4, 1.0)
