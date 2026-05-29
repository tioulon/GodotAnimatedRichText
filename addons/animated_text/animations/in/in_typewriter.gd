## Typewriter — glyph snaps fully visible once its window opens.
## Use a small stagger_delay (0.02–0.05) and short in_duration for retro dialog.
@tool
class_name InTypewriter
extends InAnimation

## Optional scale pop as each glyph appears.
@export var pop: bool = true
@export var pop_scale: float = 1.35

func _init() -> void:
	resource_name = "InTypewriter"
	easing = ATEasing.Type.OUT_QUAD

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	if t <= 0.0:
		mod.alpha = 0.0
		return
	mod.alpha = 1.0
	if pop:
		# Pop over the first 40% of the glyph window
		var pt := sub(t, 0.0, 0.4)
		var s := lerpf(pop_scale, 1.0, eased(pt))
		mod.scale = Vector2(s, s)
