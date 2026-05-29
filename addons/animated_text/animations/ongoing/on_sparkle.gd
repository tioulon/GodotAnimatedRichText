## Sparkle — chars randomly pop bright with a tiny scale-up, like glints of light.
@tool
class_name OnSparkle
extends OngoingAnimation

@export var sparkle_color: Color = Color(1.0, 1.0, 0.85)
@export var scale_pop: float = 0.25
@export var rate: float = 2.0           ## sparkle events per char per second (avg)
@export var duration: float = 0.25      ## how long each sparkle lasts (s)

func _init() -> void:
	resource_name = "OnSparkle"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	# Each char has its own pseudo-random sparkle schedule.
	var period := 1.0 / maxf(rate, 0.01)
	# Stagger each char's cycle by a hashed phase.
	var h := (idx * 2654435761)
	h = h ^ (h >> 15)
	var phase := float(h & 0xFFFF) / float(0xFFFF) * period
	var local := fmod(time + phase, period)
	if local < duration:
		var s := sin((local / duration) * PI)   # 0→1→0
		mod.color = mod.color.lerp(sparkle_color, s)
		var sc := 1.0 + s * scale_pop
		mod.scale *= Vector2(sc, sc)
