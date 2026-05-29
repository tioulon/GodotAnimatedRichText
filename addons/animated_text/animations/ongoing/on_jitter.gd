## Jitter — small per-glyph snapping at a low frame rate (dot-matrix feel).
## Uses cheap hash noise (no RNG allocation in the hot path).
@tool
class_name OnJitter
extends OngoingAnimation

@export var amplitude: float = 1.0
@export var rate: float = 10.0

func _init() -> void:
	resource_name = "OnJitter"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var tick := int(time * rate)
	mod.offset.x += OnShake._noise(tick, idx, 2) * amplitude
	mod.offset.y += OnShake._noise(tick, idx, 3) * amplitude
