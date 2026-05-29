## Drop — chars fall in from above with accelerating gravity; subtle squash on land.
@tool
class_name InDrop
extends InAnimation

@export var height: float = 24.0        ## start height above rest (px)
@export var squash: bool = true         ## squash/stretch near landing
@export var fade: bool = true

func _init() -> void:
	resource_name = "InDrop"
	easing = ATEasing.Type.IN_QUAD       ## accelerate downward

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.offset.y = -(1.0 - e) * height
	if squash and t > 0.8:
		# brief vertical squash, horizontal stretch as it lands
		var s := (t - 0.8) / 0.2
		var squish := sin(s * PI) * 0.18
		mod.scale = Vector2(1.0 + squish, 1.0 - squish)
	if fade:
		mod.alpha = minf(t * 4.0, 1.0)
