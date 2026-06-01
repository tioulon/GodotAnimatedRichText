## ATGlyphEffect — the RichTextEffect bridge.
## RichTextLabel calls _process_custom_fx() once per glyph per frame for glyphs
## wrapped in [animated_text]...[/animated_text]. We route it to the owning
## AnimatedRichLabel, which applies the per-glyph transform.
@tool
class_name ATGlyphEffect
extends RichTextEffect

var bbcode := "animated_text"
var label: Node = null

func _process_custom_fx(ch: CharFXTransform) -> bool:
	if label == null:
		return true
	return label._fx_apply(ch)
