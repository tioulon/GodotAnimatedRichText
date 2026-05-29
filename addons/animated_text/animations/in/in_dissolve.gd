## Dissolve — glyphs appear in a randomized order (CRT power-on feel).
## Best with stagger_delay = 0 so all glyphs share the same window and the
## randomized per-glyph thresholds drive the reveal.
@tool
class_name InDissolve
extends InAnimation

@export var dissolve_seed: int = 7
@export var flash: bool = false
@export var flash_brightness: float = 2.0

func _init() -> void:
	resource_name = "InDissolve"
	easing = ATEasing.Type.LINEAR

func apply(mod: CharMod, t: float, idx: int, _total: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dissolve_seed * 92821 + idx)
	var threshold := rng.randf_range(0.0, 0.9)
	if t < threshold:
		mod.alpha = 0.0
		return
	mod.alpha = 1.0
	if flash:
		var ft := clampf((t - threshold) / 0.06, 0.0, 1.0)
		var b := lerpf(flash_brightness, 1.0, ft)
		mod.color = Color(b, b, b, 1.0)
