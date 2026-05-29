## Glitch — chars stutter in with horizontal slice jumps and a brief color tear.
## Great for sci-fi / hacker / damaged-screen reveals.
@tool
class_name InGlitch
extends InAnimation

@export var max_slice: float = 10.0     ## max horizontal jump (px)
@export var tear_color: Color = Color(0.3, 1.0, 0.9)
@export var settle: float = 0.7         ## fraction of window spent glitching

func _init() -> void:
	resource_name = "InGlitch"
	easing = ATEasing.Type.OUT_QUAD

func apply(mod: CharMod, t: float, idx: int, _total: int) -> void:
	if t <= 0.0:
		mod.alpha = 0.0
		return
	mod.alpha = 1.0
	if t < settle:
		# Pseudo-random slice based on a coarse time tick
		var tick := int(t * 30.0)
		var h := (tick * 73856093) ^ (idx * 19349663)
		h = (h ^ (h >> 13)) * 1274126177
		var n := (float(h & 0xFFFF) / float(0xFFFF)) * 2.0 - 1.0
		mod.offset.x = n * max_slice * (1.0 - t / settle)
		# Color tear flickers on odd ticks
		if (tick & 1) == 0:
			mod.color = tear_color
