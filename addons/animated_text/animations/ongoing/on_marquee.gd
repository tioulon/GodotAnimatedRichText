## Marquee — a travelling horizontal ripple, like a scrolling sign: each glyph
## eases left/right in a continuous wave. Distinct from OnWave (vertical bob).
@tool
class_name OnMarquee
extends OngoingAnimation

@export var amplitude: float = 3.0
@export var speed: float = 2.5
@export var frequency: float = 0.6      ## spatial frequency along the text
@export var vertical_mix: float = 0.0   ## add a little vertical for a slosh

func _init() -> void:
	resource_name = "OnMarquee"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var phase := time * speed - idx * frequency
	mod.offset.x += sin(phase) * amplitude
	if vertical_mix > 0.0:
		mod.offset.y += cos(phase) * amplitude * vertical_mix
