## Drop out — gravity takes the glyphs: they accelerate downward and fade,
## with a little rotation, like letters falling off a shelf.
@tool
class_name OutDrop
extends OutAnimation

@export var distance: float = 30.0
@export var tumble_degrees: float = 40.0
@export var fade: bool = true

func _init() -> void:
	resource_name = "OutDrop"
	easing = ATEasing.Type.IN_QUAD       ## accelerate downward

func apply(mod: CharMod, t: float, idx: int, _total: int) -> void:
	var e := eased(t)
	mod.offset.y = e * distance
	mod.rotation = deg_to_rad(tumble_degrees) * e * (1.0 if (idx & 1) == 0 else -1.0)
	if fade:
		mod.alpha = 1.0 - sub(t, 0.5, 1.0)
