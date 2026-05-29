## Breathe — the whole text gently scales up and down in unison (calm, synced).
@tool
class_name OnBreathe
extends OngoingAnimation

@export var amount: float = 0.06        ## peak scale increase
@export var speed: float = 0.6          ## breaths per second

func _init() -> void:
	resource_name = "OnBreathe"

func apply(mod: CharMod, time: float, _idx: int, _total: int) -> void:
	var u := (sin(time * speed * TAU) + 1.0) * 0.5
	var s := 1.0 + u * amount
	mod.scale *= Vector2(s, s)
