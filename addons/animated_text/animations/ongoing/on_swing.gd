## Swing — each glyph swings like a pendulum from a top pivot (arc), phase-
## offset along the text. Distinct from OnWobble (rocks around its center).
@tool
class_name OnSwing
extends OngoingAnimation

@export var angle: float = 12.0
@export var speed: float = 1.5
@export var char_phase: float = 0.35

func _init() -> void:
	resource_name = "OnSwing"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	mod.pivot = Vector2(0.5, 0.0)        # hang from the top
	mod.rotation += sin(time * speed * TAU + idx * char_phase) * deg_to_rad(angle)
