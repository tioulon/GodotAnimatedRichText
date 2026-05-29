## Bounce — glyph drops/launches into place with a bounce.
@tool
class_name InBounce
extends InAnimation

enum Axis { VERTICAL, HORIZONTAL, SCALE }
@export var axis: Axis = Axis.VERTICAL
@export var distance: float = 14.0
@export var fade: bool = true

func _init() -> void:
	resource_name = "InBounce"
	easing = ATEasing.Type.OUT_BOUNCE

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	match axis:
		Axis.VERTICAL:   mod.offset.y = (1.0 - e) * distance
		Axis.HORIZONTAL: mod.offset.x = (1.0 - e) * distance
		Axis.SCALE:      var s := e; mod.scale = Vector2(s, s)
	if fade:
		mod.alpha = minf(t * 3.0, 1.0)
