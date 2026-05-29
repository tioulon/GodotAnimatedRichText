## Orbit — each char traces a small circle continuously, phase-offset along text.
@tool
class_name OnOrbit
extends OngoingAnimation

@export var radius: float = 2.0
@export var speed: float = 2.0          ## revolutions per second
@export var char_phase: float = 0.4     ## phase offset per char (radians)

func _init() -> void:
	resource_name = "OnOrbit"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var ang := time * speed * TAU + idx * char_phase
	mod.offset.x += cos(ang) * radius
	mod.offset.y += sin(ang) * radius
