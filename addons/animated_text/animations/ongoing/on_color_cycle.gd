## Color Cycle — smoothly blends each char between two colors over time,
## phase-offset along the text. Subtler than a full rainbow.
@tool
class_name OnColorCycle
extends OngoingAnimation

@export var color_a: Color = Color(1.0, 0.4, 0.4)
@export var color_b: Color = Color(0.4, 0.6, 1.0)
@export var speed: float = 1.0          ## full cycles per second
@export var char_offset: float = 0.15   ## phase offset per char

func _init() -> void:
	resource_name = "OnColorCycle"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var u := (sin((time * speed + idx * char_offset) * TAU) + 1.0) * 0.5
	mod.color = mod.color * color_a.lerp(color_b, u)
