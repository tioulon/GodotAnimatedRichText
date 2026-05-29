## Rainbow — cycles glyph hue over time.
@tool
class_name OnRainbow
extends OngoingAnimation

@export var speed: float = 120.0       ## degrees/sec
@export var char_offset: float = 28.0  ## hue offset per glyph (deg)
@export_range(0.0,1.0) var saturation: float = 1.0
@export_range(0.0,1.0) var value: float = 1.0
@export_range(0.0,1.0) var mix: float = 1.0

func _init() -> void:
	resource_name = "OnRainbow"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var hue := fmod(time * speed / 360.0 + idx * char_offset / 360.0, 1.0)
	if hue < 0.0: hue += 1.0
	var rc := Color.from_hsv(hue, saturation, value)
	mod.color = mod.color.lerp(rc, mix)
