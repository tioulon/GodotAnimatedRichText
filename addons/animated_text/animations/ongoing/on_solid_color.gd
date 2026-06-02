## Solid Color — tints every glyph a single constant color.
##
## Simplest possible color effect: no movement, no cycling, just a flat color
## multiplied onto the text. Useful on its own, or combined with movement
## effects (e.g. OnWave) to recolor while animating, or scoped to a region via
## bbcode_tag to color just part of the text.
@tool
class_name OnSolidColor
extends OngoingAnimation

## The color applied to every glyph (multiplied onto the existing color).
@export var color: Color = Color.WHITE

## Optional pulse between `color` and `color_to` (set pulse_speed > 0 to enable).
@export var color_to: Color = Color.WHITE
@export var pulse_speed: float = 0.0    ## full pulses per second (0 = static)

func _init() -> void:
	resource_name = "OnSolidColor"

func apply(mod: CharMod, time: float, _idx: int, _total: int) -> void:
	if pulse_speed > 0.0:
		var u := (sin(time * pulse_speed * TAU) + 1.0) * 0.5
		mod.color = mod.color * color.lerp(color_to, u)
	else:
		mod.color = mod.color * color
