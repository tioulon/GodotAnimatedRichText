## OngoingAnimation — base class for continuous / looping effects.
##
## These run every frame while the label is visible (and optionally during
## the in-animation as each glyph settles). They are applied ADDITIVELY and
## may be stacked — assign several to AnimatedRichLabel.ongoing_animations.
##
## Unlike In/Out animations there is no normalized `t`; you get the absolute
## loop time in seconds, so effects are continuous and seamless.
@tool
class_name OngoingAnimation
extends Resource

## Master strength multiplier for this effect (0 = off, 1 = full).
@export_range(0.0, 4.0, 0.01) var strength: float = 1.0

## Optional scope tag. When set (e.g. "g"), this animation only applies to text
## wrapped in that custom tag — [g]...[/g] — instead of the whole label.
## Leave empty to apply everywhere (the default). The tag is stripped from the
## visible text; it just marks a region. Works after tr(), so it's translatable.
@export var bbcode_tag: String = ""

## Override this. Modify `mod` additively for the given glyph.
##   time:  absolute loop time in seconds (continuous)
func apply(_mod: CharMod, _time: float, _idx: int, _total: int) -> void:
	pass
