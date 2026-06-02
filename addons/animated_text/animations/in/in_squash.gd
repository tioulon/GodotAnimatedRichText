## Squash — glyph drops in flattened vertically then springs to full height
## (a vertical squash-and-stretch, distinct from the horizontal Stretch).
@tool
class_name InSquash
extends InAnimation

@export var squash_y: float = 0.2
@export var overshoot_y: float = 1.25
@export var fade: bool = true

func _init() -> void:
	resource_name = "InSquash"
	easing = ATEasing.Type.OUT_CUBIC

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	mod.pivot = Vector2(0.5, 1.0)   # sit on the baseline
	# squash -> overshoot tall -> settle, via a small 3-key shape
	var sy: float
	if t < 0.6:
		sy = lerpf(squash_y, overshoot_y, eased(sub(t, 0.0, 0.6)))
	else:
		sy = lerpf(overshoot_y, 1.0, eased(sub(t, 0.6, 1.0)))
	# inverse-ish width so volume feels preserved
	var sx := 1.0 + (1.0 - sy) * 0.4
	mod.scale = Vector2(sx, sy)
	if fade:
		mod.alpha = minf(t * 4.0, 1.0)
