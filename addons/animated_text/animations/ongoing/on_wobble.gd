## Wobble — glyphs rock back and forth in rotation.
@tool
class_name OnWobble
extends OngoingAnimation

@export var angle: float = 8.0   ## degrees
@export var speed: float = 2.0
@export var char_phase: float = 0.5
@export var breathe: bool = false
@export var breathe_amount: float = 0.04

func _init() -> void:
	resource_name = "OnWobble"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var phase := time * speed * PI + idx * char_phase
	mod.rotation += sin(phase) * deg_to_rad(angle)
	if breathe:
		var s := 1.0 + sin(phase) * breathe_amount
		mod.scale *= Vector2(s, s)
