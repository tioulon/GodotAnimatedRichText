## Bounce — chars hop upward in a travelling wave, returning to rest between hops.
@tool
class_name OnBounce
extends OngoingAnimation

@export var height: float = 6.0
@export var speed: float = 2.0          ## hops per second (overall)
@export var char_delay: float = 0.12    ## delay between chars (travelling hop)

func _init() -> void:
	resource_name = "OnBounce"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var phase := (time - idx * char_delay) * speed
	var f: float = phase - floor(phase)         # 0..1 within this char's cycle
	# Only hop during the first half of the cycle, rest otherwise.
	var h: float = sin(f * PI) if f < 0.5 else 0.0
	mod.offset.y -= h * height
