## Dissolve out — glyphs vanish in a randomized order (reverse of InDissolve).
## Use stagger_delay = 0 so the per-glyph random thresholds drive the fade.
@tool
class_name OutDissolve
extends OutAnimation

@export var dissolve_seed: int = 11
@export var rise: float = 6.0          ## drift up slightly as they vanish

func _init() -> void:
	resource_name = "OutDissolve"
	easing = ATEasing.Type.LINEAR

func apply(mod: CharMod, t: float, idx: int, _total: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dissolve_seed * 92821 + idx)
	var threshold := rng.randf_range(0.0, 0.7)
	if t < threshold:
		mod.alpha = 1.0
		return
	var local := clampf((t - threshold) / maxf(1.0 - threshold, 0.0001), 0.0, 1.0)
	mod.alpha = 1.0 - local
	mod.offset.y = -local * rise
