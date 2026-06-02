## Cascade — glyphs tumble in from above with a rotation, like falling cards
## landing flat. Combines vertical drop + spin settle (distinct from Drop's
## straight fall and Spin's in-place rotation).
@tool
class_name InCascade
extends InAnimation

@export var height: float = 18.0
@export var spin_degrees: float = 110.0
@export var sideways: float = 8.0
@export var fade: bool = true

func _init() -> void:
	resource_name = "InCascade"
	easing = ATEasing.Type.OUT_BACK

func apply(mod: CharMod, t: float, idx: int, _total: int) -> void:
	var e := eased(t)
	var inv := 1.0 - e
	mod.offset.y = -inv * height
	mod.offset.x = inv * sideways * (1.0 if (idx & 1) == 0 else -1.0)
	mod.rotation = deg_to_rad(spin_degrees) * inv * (1.0 if (idx & 1) == 0 else -1.0)
	if fade:
		mod.alpha = sub(t, 0.0, 0.4)
