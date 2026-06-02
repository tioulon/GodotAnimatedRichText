## Glow — a smooth brightness shimmer travelling along the text (alpha + tint up).
## Distinct from OnFlicker (random dips) — this is a clean moving highlight.
@tool
class_name OnGlow
extends OngoingAnimation

@export var brightness: float = 0.6     ## extra brightness at the peak
@export var speed: float = 2.0
@export var width: float = 0.5          ## phase spread per char (highlight width)
@export var tint: Color = Color(1, 1, 1)

func _init() -> void:
	resource_name = "OnGlow"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var u := (sin(time * speed - idx * width) + 1.0) * 0.5
	var b := 1.0 + u * brightness
	mod.color = mod.color * Color(tint.r * b, tint.g * b, tint.b * b, 1.0)
