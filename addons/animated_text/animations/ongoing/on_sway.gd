## Sway — the text leans side to side as a whole, like a hanging sign.
@tool
class_name OnSway
extends OngoingAnimation

@export var angle: float = 4.0          ## max lean in degrees
@export var speed: float = 0.8          ## sways per second

func _init() -> void:
	resource_name = "OnSway"

func apply(mod: CharMod, time: float, idx: int, total: int) -> void:
	var lean := sin(time * speed * TAU) * deg_to_rad(angle)
	mod.rotation += lean
	# add a slight horizontal shift scaled by distance from center for a pivot feel
	var center := (total - 1) * 0.5
	mod.offset.x += lean * (idx - center) * 2.0
