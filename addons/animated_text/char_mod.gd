## CharMod — the per-character modification bundle.
##
## Every animation (in / out / ongoing) reads and writes one of these per glyph,
## per frame. AnimatedRichLabel collects the result and applies it to the
## RichTextLabel's per-glyph transform inside its custom RichTextEffect.
##
## This is a plain data container (RefCounted) — no logic, just fields.
## A single instance is reused per glyph each frame (pooled) to avoid GC churn.
class_name CharMod
extends RefCounted

## Pixel offset from the glyph's laid-out position.
var offset: Vector2 = Vector2.ZERO

## Scale around the glyph pivot (default pivot = glyph center).
var scale: Vector2 = Vector2.ONE

## Rotation in radians around the pivot.
var rotation: float = 0.0

## Color MULTIPLIER applied on top of the glyph's existing color
## (which already includes theme color + any BBCode [color] tags).
var color: Color = Color.WHITE

## Separate alpha multiplier (kept apart from color so fades compose cleanly).
var alpha: float = 1.0

## Pivot for scale/rotation, as a fraction of the glyph rect (0.5,0.5 = center).
var pivot: Vector2 = Vector2(0.5, 0.5)

func reset() -> void:
	offset   = Vector2.ZERO
	scale    = Vector2.ONE
	rotation = 0.0
	color    = Color.WHITE
	alpha    = 1.0
	pivot    = Vector2(0.5, 0.5)

## Compose another mod on top of this one (used to stack ongoing animations).
func combine(other: CharMod) -> void:
	offset   += other.offset
	scale    *= other.scale
	rotation += other.rotation
	color    *= other.color
	alpha    *= other.alpha
