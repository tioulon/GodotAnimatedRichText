## Shake — random per-glyph jitter on a fixed time grid.
## Uses a cheap integer-hash noise (no RNG allocation in the hot path).
@tool
class_name OnShake
extends OngoingAnimation

@export var amplitude: float = 2.0
@export var rate: float = 20.0   ## resamples per second

func _init() -> void:
	resource_name = "OnShake"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var tick := int(time * rate)
	mod.offset.x += _noise(tick, idx, 0) * amplitude
	mod.offset.y += _noise(tick, idx, 1) * amplitude

## Deterministic hash noise in [-1, 1]. No allocations.
static func _noise(tick: int, idx: int, axis: int) -> float:
	var h := (tick * 73856093) ^ (idx * 19349663) ^ (axis * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return (float(h & 0xFFFFFF) / float(0xFFFFFF)) * 2.0 - 1.0
