## Slide out — glyph slides away to a direction.
@tool
class_name OutSlide
extends OutAnimation

enum Dir { LEFT, RIGHT, UP, DOWN, CUSTOM }
@export var direction: Dir = Dir.DOWN
@export var distance: float = 14.0
@export var custom_dir: Vector2 = Vector2(0, 1)
@export var fade: bool = true

func _init() -> void:
	resource_name = "OutSlide"
	easing = ATEasing.Type.IN_CUBIC

func apply(mod: CharMod, t: float, _idx: int, _total: int) -> void:
	var e := eased(t)
	mod.offset = _vec() * distance * e
	if fade:
		mod.alpha = 1.0 - sub(t, 0.4, 1.0)

func _vec() -> Vector2:
	match direction:
		Dir.LEFT:  return Vector2(-1, 0)
		Dir.RIGHT: return Vector2( 1, 0)
		Dir.UP:    return Vector2( 0,-1)
		Dir.DOWN:  return Vector2( 0, 1)
		Dir.CUSTOM: return custom_dir.normalized()
	return Vector2(0, 1)
