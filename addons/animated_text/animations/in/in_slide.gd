## Slide — glyph slides in from a direction.
@tool
class_name InSlide
extends InAnimation

enum Dir { LEFT, RIGHT, UP, DOWN, CUSTOM }
@export var direction: Dir = Dir.UP
@export var distance: float = 12.0
@export var custom_dir: Vector2 = Vector2(0, -1)
@export var fade: bool = true
@export_range(0.0,1.0) var fade_end: float = 0.6

func _init() -> void:
	resource_name = "InSlide"
	easing = ATEasing.Type.OUT_CUBIC

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.offset = _vec() * distance * (1.0 - e)
	if fade:
		mod.alpha = sub(t, 0.0, fade_end)

func _vec() -> Vector2:
	match direction:
		Dir.LEFT:  return Vector2(-1, 0)
		Dir.RIGHT: return Vector2( 1, 0)
		Dir.UP:    return Vector2( 0,-1)
		Dir.DOWN:  return Vector2( 0, 1)
		Dir.CUSTOM: return custom_dir.normalized()
	return Vector2(0,-1)
