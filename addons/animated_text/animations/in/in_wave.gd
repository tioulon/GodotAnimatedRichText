## Wave — glyphs rise up with an overshoot, flowing via the stagger.
@tool
class_name InWave
extends InAnimation

@export var rise: float = 10.0
@export var fade: bool = true
@export_range(0.0,1.0) var fade_end: float = 0.5

func _init() -> void:
	resource_name = "InWave"
	easing = ATEasing.Type.OUT_BACK

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.offset.y = (1.0 - e) * rise
	if fade:
		mod.alpha = sub(t, 0.0, fade_end)
