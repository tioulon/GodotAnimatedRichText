## InAnimation — base class for entrance animations.
##
## Subclass and override apply(). Save as a .tres and assign to
## AnimatedRichLabel.in_animation.
##
## t = 0.0  →  glyph at its HIDDEN / start pose
## t = 1.0  →  glyph at its RESTING pose (don't touch fields you don't use)
##
## The label handles per-character stagger timing; `t` is already the
## eased-or-raw normalized progress for THIS glyph. Use eased() to shape it.
@tool
class_name InAnimation
extends Resource

## Easing applied to the raw progress. Ignored if curve is set.
@export var easing: ATEasing.Type = ATEasing.Type.OUT_CUBIC
## Optional custom easing curve (overrides easing enum). Y may exceed [0,1].
@export var curve: Curve

## Override this. Modify `mod` for the given glyph.
##   mod:   the CharMod to write to (already reset to identity)
##   t:     normalized progress [0..1] for this glyph (raw, un-eased)
##   idx:   glyph index
##   total: total glyph count
func apply(_mod: CharMod, _t: float, _idx: int, _total: int) -> void:
	pass

## Convenience: eased progress using this animation's easing/curve.
func eased(t: float) -> float:
	return ATEasing.resolve(t, easing, curve)

## Linear sub-range remap, e.g. fade only during [0, 0.5] of the window.
func sub(t: float, from: float, to: float) -> float:
	return clampf((t - from) / maxf(to - from, 0.0001), 0.0, 1.0)
