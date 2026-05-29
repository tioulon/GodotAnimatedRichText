## Flicker — random per-char brightness dips, like a faulty neon sign or candle.
@tool
class_name OnFlicker
extends OngoingAnimation

@export_range(0.0, 1.0) var min_alpha: float = 0.35
@export var rate: float = 14.0          ## resamples per second
@export var dip_chance: float = 0.25    ## fraction of chars dimmed each tick

func _init() -> void:
	resource_name = "OnFlicker"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var tick := int(time * rate)
	var h := (tick * 73856093) ^ (idx * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	var n := float(h & 0xFFFFFF) / float(0xFFFFFF)
	if n < dip_chance:
		# map [0,dip_chance) -> dim amount
		var k := n / maxf(dip_chance, 0.0001)
		mod.alpha *= lerpf(min_alpha, 1.0, k)
