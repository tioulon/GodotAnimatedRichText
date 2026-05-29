## OutAnimation — base class for exit animations.
##
## t = 0.0  →  glyph at its RESTING pose
## t = 1.0  →  glyph fully HIDDEN / gone
@tool
class_name OutAnimation
extends Resource

@export var easing: ATEasing.Type = ATEasing.Type.IN_CUBIC
@export var curve: Curve

func apply(_mod: CharMod, _t: float, _idx: int, _total: int) -> void:
	pass

func eased(t: float) -> float:
	return ATEasing.resolve(t, easing, curve)

func sub(t: float, from: float, to: float) -> float:
	return clampf((t - from) / maxf(to - from, 0.0001), 0.0, 1.0)
