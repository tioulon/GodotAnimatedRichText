## Flip 3D — glyph rotates in on a vertical axis (fake 3D card flip) by driving
## scale.x from 0 → 1, optionally darkening at the thin edge for depth.
@tool
class_name InFlip3D
extends InAnimation

@export var from_back: bool = true       ## start mirrored (scale.x negative)
@export var edge_darken: float = 0.5     ## how dark the thin edge gets (0..1)

func _init() -> void:
	resource_name = "InFlip3D"
	easing = ATEasing.Type.OUT_CUBIC

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	var sx := lerpf(-1.0 if from_back else 0.0, 1.0, e)
	mod.scale = Vector2(sx, 1.0)
	# darken toward the edge-on moment (when |sx| is small)
	var face := absf(sx)
	var b := lerpf(1.0 - edge_darken, 1.0, face)
	mod.color = Color(b, b, b, 1.0)
	mod.alpha = minf(t * 5.0, 1.0)
