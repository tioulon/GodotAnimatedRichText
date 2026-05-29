## Swirl — chars spiral inward from a circular offset while rotating to rest.
@tool
class_name InSwirl
extends InAnimation

@export var radius: float = 20.0        ## starting distance from rest (px)
@export var spins: float = 1.0          ## how many turns during entry
@export var alternate: bool = true      ## alternate spiral direction per char
@export var fade: bool = true

func _init() -> void:
	resource_name = "InSwirl"
	easing = ATEasing.Type.OUT_CUBIC

func apply(mod: CharMod, t: float, idx: int, _total: int) -> void:
	var e := eased(t)
	var dir := 1.0
	if alternate and (idx & 1) == 1:
		dir = -1.0
	var ang := (1.0 - e) * spins * TAU * dir
	var r := (1.0 - e) * radius
	mod.offset = Vector2(cos(ang), sin(ang)) * r
	mod.rotation = ang * 0.5
	if fade:
		mod.alpha = sub(t, 0.0, 0.5)
