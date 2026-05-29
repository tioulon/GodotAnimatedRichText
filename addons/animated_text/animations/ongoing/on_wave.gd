## Wave — sine bob travelling along the text.
@tool
class_name OnWave
extends OngoingAnimation

@export var amplitude: float = 3.0
@export var speed: float = 3.0
@export var frequency: float = 0.8
@export var horizontal: bool = false
@export var h_amplitude: float = 1.0

func _init() -> void:
	resource_name = "OnWave"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var phase := time * speed + idx * frequency
	mod.offset.y += sin(phase) * amplitude
	if horizontal:
		mod.offset.x += cos(phase) * h_amplitude
