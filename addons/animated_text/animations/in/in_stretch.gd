## Stretch — char enters squashed wide & short, then snaps to normal (cartoon pop).
@tool
class_name InStretch
extends InAnimation

@export var stretch_x: float = 1.8
@export var stretch_y: float = 0.4
@export var fade: bool = true

func _init() -> void:
	resource_name = "InStretch"
	easing = ATEasing.Type.OUT_BACK

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.scale = Vector2(lerpf(stretch_x, 1.0, e), lerpf(stretch_y, 1.0, e))
	if fade:
		mod.alpha = minf(t * 3.0, 1.0)
