## Scale out — glyph shrinks away.
@tool
class_name OutScale
extends OutAnimation

@export var to_scale: float = 0.0
@export var fade: bool = true

func _init() -> void:
	resource_name = "OutScale"
	easing = ATEasing.Type.IN_BACK

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	var s := lerpf(1.0, to_scale, e)
	mod.scale = Vector2(s, s)
	if fade:
		mod.alpha = 1.0 - sub(t, 0.5, 1.0)
