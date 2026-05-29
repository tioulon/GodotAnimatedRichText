## Pulse — rhythmic scale (and optional alpha) breathing.
@tool
class_name OnPulse
extends OngoingAnimation

@export var scale_amount: float = 0.12
@export var frequency: float = 1.5
@export var char_phase: float = 0.3
@export var alpha_amount: float = 0.0

func _init() -> void:
	resource_name = "OnPulse"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var phase := time * frequency * TAU + idx * char_phase
	var u := (sin(phase) + 1.0) * 0.5
	var s := 1.0 + u * scale_amount
	mod.scale *= Vector2(s, s)
	if alpha_amount > 0.0:
		mod.alpha *= 1.0 - u * alpha_amount
