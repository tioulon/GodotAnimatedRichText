## Pendulum — each glyph swings into place from an offset pivot, like hanging
## letters settling. Rotation pivots near the top so it arcs rather than spins.
@tool
class_name InPendulum
extends InAnimation

@export var swing_degrees: float = 75.0
@export var from_left: bool = true
@export var fade: bool = true

func _init() -> void:
	resource_name = "InPendulum"
	easing = ATEasing.Type.OUT_ELASTIC

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.pivot = Vector2(0.5, 0.0)   # hang from the top
	var dir := -1.0 if from_left else 1.0
	mod.rotation = deg_to_rad(swing_degrees) * dir * (1.0 - e)
	if fade:
		mod.alpha = sub(t, 0.0, 0.3)
