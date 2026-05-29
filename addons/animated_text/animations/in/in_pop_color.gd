## Pop Color — typewriter reveal where each char flashes a highlight color as it
## appears, then settles to its normal color.
@tool
class_name InPopColor
extends InAnimation

@export var flash_color: Color = Color(1.0, 0.9, 0.3)
@export var pop_scale: float = 1.4

func _init() -> void:
	resource_name = "InPopColor"
	easing = ATEasing.Type.OUT_QUAD

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	if t <= 0.0:
		mod.alpha = 0.0
		return
	mod.alpha = 1.0
	# scale pop + color flash over the first 50%
	var p := sub(t, 0.0, 0.5)
	var e := eased(p)
	var s := lerpf(pop_scale, 1.0, e)
	mod.scale = Vector2(s, s)
	mod.color = flash_color.lerp(Color.WHITE, e)
