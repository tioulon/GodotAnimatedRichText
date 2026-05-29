## Zoom — char rushes in from oversized to normal with a quick fade (impact title).
@tool
class_name InZoom
extends InAnimation

@export var from_scale: float = 4.0
@export var fade: bool = true

func _init() -> void:
	resource_name = "InZoom"
	easing = ATEasing.Type.OUT_EXPO

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	var s := lerpf(from_scale, 1.0, e)
	mod.scale = Vector2(s, s)
	if fade:
		mod.alpha = sub(t, 0.0, 0.35)
