## ATGlyphEffect — the RichTextEffect bridge.
##
## RichTextLabel calls _process_custom_fx() once per glyph per frame when the
## glyph is wrapped in [animated_text]...[/animated_text] bbcode. We use that
## hook to apply the per-glyph transform computed by AnimatedRichLabel.
##
## The whole visible text is wrapped in this single effect by the label, so
## every glyph routes through here. We read the precomputed CharMod for the
## glyph's visible index from the owning label — no allocation in the hot path.
@tool
class_name ATGlyphEffect
extends RichTextEffect

# bbcode tag name → [animated_text]...[/animated_text]
var bbcode := "animated_text"

## Set by AnimatedRichLabel right after instantiation.
var label: Node = null

func _process_custom_fx(ch: CharFXTransform) -> bool:
	if label == null:
		return true
	# relative_index is the glyph's index within the effect's text run,
	# which (since we wrap the entire text) equals the visible glyph index.
	return label._fx_apply(ch)
