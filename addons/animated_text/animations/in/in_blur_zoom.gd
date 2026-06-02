## Blur Zoom — glyph starts oversized and faint, then shrinks and sharpens into
## place (a soft focus-pull, distinct from Zoom's hard impact arrival).
@tool
class_name InBlurZoom
extends InAnimation

@export var from_scale: float = 2.2
@export var ghost_alpha: float = 0.15    ## starting faintness

func _init() -> void:
	resource_name = "InBlurZoom"
	easing = ATEasing.Type.OUT_QUART

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	var s := lerpf(from_scale, 1.0, e)
	mod.scale = Vector2(s, s)
	# alpha ramps from faint to full as it sharpens
	mod.alpha = lerpf(ghost_alpha, 1.0, eased(t))
