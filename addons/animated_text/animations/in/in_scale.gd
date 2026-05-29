## Scale — glyph grows from a small/zero size.
@tool
class_name InScale
extends InAnimation

@export var from_scale: float = 0.0
@export var fade: bool = true
@export var uniform: bool = true        ## scale X and Y together
@export var from_scale_y: float = 0.0   ## used when uniform = false

func _init() -> void:
	resource_name = "InScale"
	easing = ATEasing.Type.OUT_BACK

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	var sx := lerpf(from_scale, 1.0, e)
	var sy := sx if uniform else lerpf(from_scale_y, 1.0, e)
	mod.scale = Vector2(sx, sy)
	if fade:
		mod.alpha = sub(t, 0.0, 0.5)
