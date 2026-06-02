## Color Cycle — smoothly blends each glyph through a list of colors over time,
## phase-offset along the text so the colors travel across the word.
##
## Provide any number of colors in `colors` (2+). The cycle wraps seamlessly
## from the last color back to the first. If `colors` is empty, it falls back
## to the simple two-color `color_a` → `color_b` blend.
@tool
class_name OnColorCycle
extends OngoingAnimation

## The palette to cycle through (in order). Wraps from last back to first.
@export var colors: Array[Color] = [
	Color(1.0, 0.4, 0.4),
	Color(1.0, 0.85, 0.3),
	Color(0.4, 0.8, 0.5),
	Color(0.4, 0.6, 1.0),
]
@export var speed: float = 1.0          ## full cycles through the palette per second
@export var char_offset: float = 0.15   ## phase offset per char (0 = all in sync)
@export_range(0.0, 1.0) var mix: float = 1.0   ## how strongly to apply the color

## Fallback two-color blend, used only when `colors` has fewer than 2 entries.
@export var color_a: Color = Color(1.0, 0.4, 0.4)
@export var color_b: Color = Color(0.4, 0.6, 1.0)

func _init() -> void:
	resource_name = "OnColorCycle"

func apply(mod: CharMod, time: float, idx: int, _total: int) -> void:
	var target: Color
	var n := colors.size()
	if n >= 2:
		# Position in [0, n) around the palette, wrapping seamlessly.
		var pos := fmod(time * speed + float(idx) * char_offset, 1.0)
		if pos < 0.0:
			pos += 1.0
		var scaled := pos * float(n)
		var i := int(scaled) % n
		var j := (i + 1) % n
		var f: float = scaled - floor(scaled)
		target = colors[i].lerp(colors[j], f)
	else:
		var u := (sin((time * speed + float(idx) * char_offset) * TAU) + 1.0) * 0.5
		target = color_a.lerp(color_b, u)
	mod.color = mod.color * Color.WHITE.lerp(target, mix)
