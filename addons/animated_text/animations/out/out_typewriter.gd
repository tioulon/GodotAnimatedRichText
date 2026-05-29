## Typewriter out — glyph snaps invisible. Use RIGHT_TO_LEFT stagger for a backspace erase.
@tool
class_name OutTypewriter
extends OutAnimation

@export var shrink: bool = true
@export var shrink_to: float = 0.5

func _init() -> void:
	resource_name = "OutTypewriter"
	easing = ATEasing.Type.LINEAR

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	if t >= 0.5:
		mod.alpha = 0.0
		return
	if shrink:
		var s := lerpf(1.0, shrink_to, t / 0.5)
		mod.scale = Vector2(s, s)
