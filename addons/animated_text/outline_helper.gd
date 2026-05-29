## OutlineHelper — one-call setup for the text outline shader.
##
## Usage:
##   OutlineHelper.apply(my_label, {
##       "thickness": 3.0,
##       "color": Color.BLACK,
##       "top_color": Color.WHITE,   # optional two-tone top edge
##       "top_height": 1.0,
##   })
##
## For a PER-CHARACTER outline (behind each glyph individually) use the
## built-in RichTextLabel theme outline instead — see OutlineHelper.apply_theme().
@tool
class_name OutlineHelper
extends RefCounted

const SHADER_PATH := "res://addons/animated_text/shaders/text_outline.gdshader"

## Apply the unified silhouette outline shader to a CanvasItem (e.g. a label).
## opts keys (all optional):
##   thickness:float, color:Color, top_color:Color, top_height:float,
##   enable_top_color:bool, quality:int
static func apply(node: CanvasItem, opts: Dictionary = {}) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load(SHADER_PATH)
	mat.set_shader_parameter("outline_thickness", opts.get("thickness", 2.0))
	mat.set_shader_parameter("outline_color",     opts.get("color", Color.BLACK))
	var has_top: bool = opts.has("top_color") or opts.get("enable_top_color", false)
	mat.set_shader_parameter("enable_top_color",  has_top)
	mat.set_shader_parameter("top_color",         opts.get("top_color", Color.WHITE))
	mat.set_shader_parameter("top_height",        opts.get("top_height", 1.0))
	mat.set_shader_parameter("quality",           opts.get("quality", 16))
	node.material = mat
	return mat

## Per-character outline using RichTextLabel's native theme outline.
## This is drawn per-glyph in correct order by the engine (behind each char).
static func apply_theme(label: RichTextLabel, color: Color = Color.BLACK, size: int = 4) -> void:
	label.add_theme_color_override("font_outline_color", color)
	label.add_theme_constant_override("outline_size", size)

## Remove a per-character theme outline.
static func clear_theme(label: RichTextLabel) -> void:
	label.remove_theme_color_override("font_outline_color")
	label.remove_theme_constant_override("outline_size")
