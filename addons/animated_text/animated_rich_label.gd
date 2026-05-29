## AnimatedRichLabel — animated text built ON TOP of RichTextLabel.
##
## Because this IS a RichTextLabel, you get every feature for free:
##   • All theme overrides (font, font_size, colors, outline, shadow, spacing…)
##   • Full BBCode ([b], [i], [color], [font], [img], tables, etc.)
##   • Text wrapping, alignment, scrolling, fit-content, etc.
##
## On top of that it adds per-character entrance / exit / ongoing animations.
##
## ANIMATION SLOTS (kept separate to avoid confusion):
##   in_animation        : InAnimation        — plays once on play_in()
##   out_animation       : OutAnimation       — plays once on play_out()
##   ongoing_animations  : Array[OngoingAnimation] — loop continuously, stackable
##
## HOW IT WORKS
##   The label wraps its whole text in a custom RichTextEffect. Godot calls back
##   per glyph per frame; we apply a precomputed transform. This is the native,
##   efficient path RichTextLabel uses for [wave]/[shake]/etc.
##
## QUICK START
##   var l := AnimatedRichLabel.new()
##   l.text = "Hello [b]world[/b]!"
##   l.in_animation = InFade.new()
##   add_child(l)
##   l.play_in()

@tool
class_name AnimatedRichLabel
extends RichTextLabel

# ═══════════════════════════════════════════════════════════════════
# Signals
# ═══════════════════════════════════════════════════════════════════
signal in_finished
signal out_finished
signal char_shown(visible_index: int)

# ═══════════════════════════════════════════════════════════════════
# Enums
# ═══════════════════════════════════════════════════════════════════
enum Phase { IDLE, IN, HOLD, OUT }

enum Stagger {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT,
	CENTER_OUT,
	EDGES_IN,
	RANDOM,
}

## How the outline is drawn.
enum OutlineMode {
	NONE,    ## no outline
	SHADER,  ## two-tone pixel-perfect outline + shadow (more control)
	NATIVE,  ## Godot's built-in font outline + shadow (no shader, very cheap, single color)
}

# ═══════════════════════════════════════════════════════════════════
# Exports — Content
# ═══════════════════════════════════════════════════════════════════
@export_group("Animated Text")

## The text to display. Supports full BBCode (bbcode is force-enabled).
@export_multiline var animated_text: String = "Hello, World!":
	set(v):
		animated_text = v
		_rewrap_needed = true
		if _ready_done: _rewrap()

# ═══════════════════════════════════════════════════════════════════
# Exports — Animation slots
# ═══════════════════════════════════════════════════════════════════
@export_group("In Animation")
@export var in_animation: InAnimation

@export_group("Out Animation")
@export var out_animation: OutAnimation

@export_group("Ongoing Animations")
## Stackable continuous effects (applied additively, in order).
@export var ongoing_animations: Array[OngoingAnimation] = []

# ═══════════════════════════════════════════════════════════════════
# Exports — Timing
# ═══════════════════════════════════════════════════════════════════
@export_group("Timing")
## Seconds between consecutive glyphs starting their in/out animation.
@export var stagger_delay: float = 0.04
## Duration of each glyph's in-animation.
@export var in_duration: float = 0.35
## Duration of each glyph's out-animation.
@export var out_duration: float = 0.28
## Order glyphs animate in.
@export var stagger: Stagger = Stagger.LEFT_TO_RIGHT
## Seed for RANDOM stagger (change for a different shuffle).
@export var random_seed: int = 0

# ═══════════════════════════════════════════════════════════════════
# Exports — Behavior
# ═══════════════════════════════════════════════════════════════════
@export_group("Behavior")
## Play the in-animation automatically when entering the tree.
@export var auto_play: bool = true
## Run ongoing animations automatically. When false, ongoing never runs unless
## you manually enter HOLD (e.g. via show_now()).
@export var run_ongoing: bool = true
## Mix ongoing animations INTO the in-animation, as if the loop was already
## playing before the text appeared. The glyph's wave/pulse/etc. is layered on
## top of its entrance the whole time, not started only after it settles.
@export var ongoing_during_in: bool = true
## Also mix ongoing into the OUT animation, so the loop keeps going as text exits.
@export var ongoing_during_out: bool = false
## Glyphs are invisible until their stagger window opens (prevents a flash of
## un-animated text for non-fading entrances like scale/spin).
@export var hide_until_started: bool = true

# ═══════════════════════════════════════════════════════════════════
# Exports — Outline + Shadow (shader applied directly to this node)
# ═══════════════════════════════════════════════════════════════════
@export_group("Outline")
## How to draw the outline:
##   SHADER = two-tone pixel-perfect outline + shadow via the shader (more control)
##   NATIVE = Godot's built-in font outline + shadow (no shader, basically free,
##            single color only — no two-tone top, but very cheap)
##   NONE   = no outline
@export var outline_mode: OutlineMode = OutlineMode.NONE:
	set(v): outline_mode = v; _refresh_outline()
## Apply the two-tone outline shader to this label. Give the node a little extra
## size/padding so the outline has room (it can't draw outside the node rect).
@export var outline_enabled: bool = false:
	set(v): outline_enabled = v; _refresh_outline()
@export var outline_color: Color = Color.BLACK:
	set(v): outline_color = v; _set_outline("outline_color", v)
@export_range(0.0, 64.0, 1.0) var outline_thickness: float = 4.0:
	set(v): outline_thickness = v; _set_outline("outline_thickness", v)
## Pixel-perfect quantization. 1 = native, 2/3/4 = chunkier (match your art).
@export_range(1.0, 16.0, 1.0) var outline_pixel_size: float = 1.0:
	set(v): outline_pixel_size = v; _set_outline("pixel_size", v)
@export_range(4, 32, 1) var outline_quality: int = 16:
	set(v): outline_quality = v; _set_outline("quality", v)

@export_subgroup("Top Color")
## Color the TOP band of the outline a second color (the pixel-art look).
@export var outline_top_enabled: bool = false:
	set(v): outline_top_enabled = v; _set_outline("top_enabled", v)
@export var outline_top_color: Color = Color.WHITE:
	set(v): outline_top_color = v; _set_outline("top_color", v)
@export_range(0.0, 64.0, 1.0) var outline_top_height: float = 2.0:
	set(v): outline_top_height = v; _set_outline("top_height", v)

@export_subgroup("Shadow")
@export var shadow_enabled: bool = false:
	set(v): shadow_enabled = v; _set_outline("shadow_enabled", v)
@export var shadow_color: Color = Color(0, 0, 0, 0.5):
	set(v): shadow_color = v; _set_outline("shadow_color", v)
@export var shadow_offset: Vector2 = Vector2(2, 2):
	set(v): shadow_offset = v; _set_outline("shadow_offset", v)

# ═══════════════════════════════════════════════════════════════════
# Exports — Editor Preview
# ═══════════════════════════════════════════════════════════════════
@export_group("Editor Preview")
## Live-play the full in → hold → out loop inside the editor. Toggle to restart.
@export var preview: bool = false:
	set(v):
		preview = v
		if Engine.is_editor_hint() and _ready_done:
			if v: _preview_reset()
			else: _stop_preview()
@export var preview_hold: float = 1.4

# ═══════════════════════════════════════════════════════════════════
# Private state
# ═══════════════════════════════════════════════════════════════════
var _phase: Phase = Phase.IDLE
var _hidden: bool = false     # explicit hide_now() state
var _anim_t: float = 0.0     # in/out clock
var _loop_t: float = 0.0     # ongoing clock (continuous, never reset mid-life)

var _effect: ATGlyphEffect
var _ready_done: bool = false
var _rewrap_needed: bool = true

var _total: int = 0
var _glyph_px: int = 16   # resolved font size in px, for glyph dimension queries
var _order: PackedInt32Array = PackedInt32Array()   # glyph idx → stagger rank
var _shown_flags: PackedByteArray = PackedByteArray()

# Pooled scratch objects — zero allocation in the per-glyph hot path
var _mod: CharMod = CharMod.new()
var _tmp: CharMod = CharMod.new()

# Preview bookkeeping
var _pv_phase: int = 0
var _pv_acc: float = 0.0

# ═══════════════════════════════════════════════════════════════════
# Lifecycle
# ═══════════════════════════════════════════════════════════════════
func _ready() -> void:
	bbcode_enabled = true
	_install_effect()
	_ready_done = true
	_rewrap()
	_refresh_outline()

	if Engine.is_editor_hint():
		if preview: _preview_reset()
		return

	if auto_play:
		play_in()
	else:
		# Not auto-playing: if we're meant to animate in and hide-until-started
		# is on, keep the text hidden until the user calls play_in(). Otherwise
		# it would incorrectly show at full opacity before any animation.
		_phase = Phase.IDLE
		if hide_until_started and in_animation != null:
			_hidden = true
		queue_redraw()

func _install_effect() -> void:
	_effect = ATGlyphEffect.new()
	_effect.label = self
	# Per Godot issue #103630: assigning a NEW array to custom_effects is the
	# reliable path. duplicate()+append or install_effect() can fail to render.
	var fx: Array = []
	for e in custom_effects:        # keep any pre-existing effects
		fx.append(e)
	fx.append(_effect)
	custom_effects = fx

# ═══════════════════════════════════════════════════════════════════
# Outline shader management (driven by the @export Outline group)
# ═══════════════════════════════════════════════════════════════════
const _OUTLINE_SHADER := "res://addons/animated_text/shaders/text_outline.gdshader"

func _refresh_outline() -> void:
	if not (is_inside_tree() or Engine.is_editor_hint()):
		return
	# Resolve effective mode: explicit outline_mode wins; else legacy bool.
	var mode := outline_mode
	if mode == OutlineMode.NONE and outline_enabled:
		mode = OutlineMode.SHADER

	# Clear native theme overrides first (so switching modes is clean).
	remove_theme_color_override("font_outline_color")
	remove_theme_constant_override("outline_size")
	remove_theme_color_override("font_shadow_color")
	remove_theme_constant_override("shadow_offset_x")
	remove_theme_constant_override("shadow_offset_y")

	if mode == OutlineMode.SHADER:
		clip_contents = false
		var mat := material as ShaderMaterial
		if mat == null or not (mat.shader is Shader) or mat.shader.resource_path != _OUTLINE_SHADER:
			mat = ShaderMaterial.new()
			mat.shader = load(_OUTLINE_SHADER)
			material = mat
		mat.set_shader_parameter("outline_enabled", true)
		mat.set_shader_parameter("outline_color", outline_color)
		mat.set_shader_parameter("outline_thickness", outline_thickness)
		mat.set_shader_parameter("pixel_size", outline_pixel_size)
		mat.set_shader_parameter("quality", outline_quality)
		mat.set_shader_parameter("top_enabled", outline_top_enabled)
		mat.set_shader_parameter("top_color", outline_top_color)
		mat.set_shader_parameter("top_height", outline_top_height)
		mat.set_shader_parameter("shadow_enabled", shadow_enabled)
		mat.set_shader_parameter("shadow_color", shadow_color)
		mat.set_shader_parameter("shadow_offset", shadow_offset)
		queue_redraw()
	elif mode == OutlineMode.NATIVE:
		clip_contents = false
		# Drop any shader material we own.
		var mat := material as ShaderMaterial
		if mat and mat.shader is Shader and mat.shader.resource_path == _OUTLINE_SHADER:
			material = null
		# Native font outline (single color, drawn by the font rasterizer — cheap).
		if outline_thickness > 0.0:
			add_theme_color_override("font_outline_color", outline_color)
			add_theme_constant_override("outline_size", int(outline_thickness))
		# Native font shadow (single color).
		if shadow_enabled:
			add_theme_color_override("font_shadow_color", shadow_color)
			add_theme_constant_override("shadow_offset_x", int(shadow_offset.x))
			add_theme_constant_override("shadow_offset_y", int(shadow_offset.y))
		queue_redraw()
	else:
		# NONE: remove our shader material if present.
		var mat := material as ShaderMaterial
		if mat and mat.shader is Shader and mat.shader.resource_path == _OUTLINE_SHADER:
			material = null

func _set_outline(param: String, value: Variant) -> void:
	# In NATIVE mode (or when params drive theme overrides) just rebuild.
	if outline_mode == OutlineMode.NATIVE:
		_refresh_outline()
		return
	if outline_mode != OutlineMode.SHADER and not outline_enabled:
		return
	var mat := material as ShaderMaterial
	if mat and mat.shader is Shader and mat.shader.resource_path == _OUTLINE_SHADER:
		mat.set_shader_parameter(param, value)
		queue_redraw()
	elif is_inside_tree() or Engine.is_editor_hint():
		_refresh_outline()

func _process(delta: float) -> void:
	if _rewrap_needed:
		_rewrap()

	if Engine.is_editor_hint():
		if preview:
			_tick_preview(delta)
		return

	match _phase:
		Phase.IN:
			_anim_t += delta
			if run_ongoing: _loop_t += delta
			if _anim_t >= _full_duration(in_duration):
				_phase = Phase.HOLD if run_ongoing else Phase.IDLE
				_anim_t = 0.0
				in_finished.emit()
		Phase.HOLD:
			_loop_t += delta
		Phase.OUT:
			_anim_t += delta
			if ongoing_during_out and run_ongoing: _loop_t += delta
			if _anim_t >= _full_duration(out_duration):
				_phase = Phase.IDLE
				_anim_t = 0.0
				out_finished.emit()
		Phase.IDLE:
			pass

	# Re-run the per-glyph effect only when something is actually moving.
	# IN/OUT always move; HOLD only if ongoing effects are present.
	var needs_redraw := false
	match _phase:
		Phase.IN, Phase.OUT:
			needs_redraw = true
		Phase.HOLD:
			needs_redraw = run_ongoing and ongoing_animations.size() > 0
		Phase.IDLE:
			needs_redraw = false
	if needs_redraw:
		queue_redraw()

# ═══════════════════════════════════════════════════════════════════
# Public API
# ═══════════════════════════════════════════════════════════════════
func play_in() -> void:
	if _rewrap_needed: _rewrap()
	_hidden  = false
	_phase   = Phase.IN
	_anim_t  = 0.0
	_loop_t  = 0.0
	_reset_shown_flags()
	queue_redraw()

func play_out() -> void:
	if _rewrap_needed: _rewrap()
	_hidden = false
	_phase  = Phase.OUT
	_anim_t = 0.0
	queue_redraw()

## Show everything instantly at rest (ongoing still runs if enabled).
func show_now() -> void:
	if _rewrap_needed: _rewrap()
	_hidden = false
	_anim_t = 0.0
	_loop_t = 0.0
	_phase  = Phase.HOLD if (run_ongoing and ongoing_animations.size() > 0) else Phase.IDLE
	queue_redraw()

func hide_now() -> void:
	_hidden = true
	_phase  = Phase.IDLE
	_anim_t = 0.0
	queue_redraw()

func stop() -> void:
	_phase = Phase.IDLE

func restart_ongoing() -> void:
	_loop_t = 0.0

func is_playing_in() -> bool:  return _phase == Phase.IN
func is_playing_out() -> bool: return _phase == Phase.OUT
func is_holding() -> bool:     return _phase == Phase.HOLD or _phase == Phase.IDLE
func glyph_count() -> int:     return _total

# ═══════════════════════════════════════════════════════════════════
# Text wrapping — install the effect tag around the whole text
# ═══════════════════════════════════════════════════════════════════
func _rewrap() -> void:
	_rewrap_needed = false
	if not is_inside_tree(): return
	# Resolve current font size for glyph dimension queries
	_glyph_px = get_theme_font_size("normal_font_size", "RichTextLabel")
	if _glyph_px <= 0:
		_glyph_px = 16
	# Wrap everything in our effect tag. BBCode inside still works.
	text = "[animated_text]" + animated_text + "[/animated_text]"
	_total = get_total_character_count()
	_build_order()
	_reset_shown_flags()

func _build_order() -> void:
	_order.resize(_total)
	match stagger:
		Stagger.LEFT_TO_RIGHT:
			for i in _total: _order[i] = i
		Stagger.RIGHT_TO_LEFT:
			for i in _total: _order[i] = _total - 1 - i
		Stagger.CENTER_OUT:
			var c := (_total - 1) * 0.5
			for i in _total: _order[i] = int(absf(i - c) * 2.0)
		Stagger.EDGES_IN:
			var c := (_total - 1) * 0.5
			for i in _total: _order[i] = int((c - absf(i - c)))
		Stagger.RANDOM:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(str(random_seed) + animated_text)
			var arr: Array[int] = Array(range(_total), TYPE_INT, "", null)
			for i in range(_total - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var t: int = arr[i]; arr[i] = arr[j]; arr[j] = t
			for i in _total: _order[i] = arr[i]

func _reset_shown_flags() -> void:
	_shown_flags.resize(_total)
	for i in _total: _shown_flags[i] = 0

# ═══════════════════════════════════════════════════════════════════
# Per-glyph hot path — called by ATGlyphEffect once per glyph per frame
# ═══════════════════════════════════════════════════════════════════
func _fx_apply(ch: CharFXTransform) -> bool:
	var idx := ch.relative_index
	if idx < 0 or idx >= _total:
		return true

	var m := _mod
	m.reset()

	var active_phase := _pv_to_phase() if (Engine.is_editor_hint() and preview) else _phase

	match active_phase:
		Phase.IN:
			_compute_in(m, idx)
		Phase.OUT:
			_compute_out(m, idx)
		Phase.HOLD:
			_compute_ongoing(m, idx)
		Phase.IDLE:
			# At rest. Apply ongoing if it should run; honor an explicit hide.
			if _hidden:
				m.alpha = 0.0
			elif run_ongoing and ongoing_animations.size() > 0:
				_compute_ongoing(m, idx)

	_write_to_transform(ch, m)
	return true

func _compute_in(m: CharMod, idx: int) -> void:
	var t := _glyph_t(idx, in_duration)

	# Glyph hasn't started its entrance yet.
	if t <= 0.0:
		if ongoing_during_in and run_ongoing and ongoing_animations.size() > 0:
			# Loop is "already happening": apply ongoing even before entrance.
			_compute_ongoing(m, idx)
			# But keep it hidden until its stagger window opens, if requested.
			if hide_until_started:
				m.alpha = 0.0
		elif hide_until_started:
			m.alpha = 0.0
		return

	# Glyph is animating in. Apply the entrance...
	if in_animation:
		in_animation.apply(m, t, idx, _total)

	# ...then mix the ongoing loop on top for the WHOLE entrance, so it looks
	# like the wave/pulse/float was running before the text appeared.
	if run_ongoing and ongoing_animations.size() > 0:
		if ongoing_during_in or t >= 1.0:
			_compute_ongoing(m, idx)

	if t >= 0.5 and _shown_flags[idx] == 0:
		_shown_flags[idx] = 1
		if not Engine.is_editor_hint():
			char_shown.emit(idx)

func _compute_out(m: CharMod, idx: int) -> void:
	var t := _glyph_t(idx, out_duration)
	if out_animation:
		out_animation.apply(m, t, idx, _total)
	if ongoing_during_out and run_ongoing and ongoing_animations.size() > 0:
		_compute_ongoing(m, idx)

func _compute_ongoing(m: CharMod, idx: int) -> void:
	for anim in ongoing_animations:
		if anim and anim.strength > 0.0:
			_tmp.reset()
			anim.apply(_tmp, _loop_t, idx, _total)
			# scale the effect contribution by strength
			if anim.strength != 1.0:
				_tmp.offset   *= anim.strength
				_tmp.rotation *= anim.strength
				_tmp.scale     = Vector2.ONE.lerp(_tmp.scale, anim.strength)
				_tmp.color     = Color.WHITE.lerp(_tmp.color, anim.strength)
				_tmp.alpha     = lerpf(1.0, _tmp.alpha, anim.strength)
			m.combine(_tmp)


# ═══════════════════════════════════════════════════════════════════
# Apply CharMod → CharFXTransform
# ═══════════════════════════════════════════════════════════════════
func _write_to_transform(ch: CharFXTransform, m: CharMod) -> void:
	# Color: multiply onto the glyph's existing color (theme + bbcode).
	# This runs for BOTH the main pass and the outline pass (ch.outline),
	# so theme outlines inherit the same fade/tint automatically.
	var col := ch.color
	col = col * m.color
	col.a *= m.alpha
	ch.color = col

	# Offset. Set absolutely (not +=): the documented fix for custom effects
	# misplacing ligature glyphs is to assign offset rather than accumulate.
	ch.offset = m.offset

	# Scale & rotation around the glyph's visual center.
	if m.scale != Vector2.ONE or m.rotation != 0.0:
		var gsize := _glyph_dimensions(ch)
		var pivot_px := gsize * m.pivot
		# Build: translate(pivot) * rotate * scale * translate(-pivot)
		var rot := Transform2D(m.rotation, Vector2.ZERO)
		var scl := Transform2D(0.0, Vector2.ZERO)
		scl.x = Vector2(m.scale.x, 0.0)
		scl.y = Vector2(0.0, m.scale.y)
		var to_pivot := Transform2D(0.0, pivot_px)
		var from_pivot := Transform2D(0.0, -pivot_px)
		var pivot_xf := to_pivot * rot * scl * from_pivot
		# Compose onto whatever transform the glyph already had.
		ch.transform = ch.transform * pivot_xf

## Approximate glyph pixel size for choosing a scale/rotation pivot.
## We intentionally avoid TextServer glyph queries (their size/outline param
## semantics vary across versions); an approximation from the font size is
## visually indistinguishable for pivoting and has zero API risk.
func _glyph_dimensions(_ch: CharFXTransform) -> Vector2:
	# Typical glyph advance ≈ 0.55×em wide, cap height ≈ 0.7×em tall.
	return Vector2(_glyph_px * 0.55, _glyph_px * 0.7)

# ═══════════════════════════════════════════════════════════════════
# Timing helpers
# ═══════════════════════════════════════════════════════════════════
func _glyph_t(idx: int, duration: float) -> float:
	if duration <= 0.0: return 1.0
	var rank := _order[idx] if idx < _order.size() else idx
	var start := rank * stagger_delay
	return clampf((_anim_t - start) / duration, 0.0, 1.0)

func _full_duration(per_glyph: float) -> float:
	if _total <= 0: return 0.0
	return per_glyph + stagger_delay * maxf(_total - 1, 0)

# ═══════════════════════════════════════════════════════════════════
# Editor preview
# ═══════════════════════════════════════════════════════════════════
func _preview_reset() -> void:
	if not is_inside_tree(): return
	_pv_phase = 0
	_pv_acc   = 0.0
	_anim_t   = 0.0
	_loop_t   = 0.0
	queue_redraw()

func _stop_preview() -> void:
	_pv_phase = 0
	_anim_t = 0.0
	_phase = Phase.IDLE
	queue_redraw()

func _pv_to_phase() -> Phase:
	match _pv_phase:
		1: return Phase.IN
		2: return Phase.HOLD
		3: return Phase.OUT
	return Phase.IDLE

func _tick_preview(delta: float) -> void:
	_pv_acc += delta
	match _pv_phase:
		0:  # brief pause then start
			if run_ongoing: _loop_t += delta   # keep loop continuous through the gap
			if _pv_acc >= 0.2:
				_pv_acc = 0.0; _anim_t = 0.0
				# Do NOT reset _loop_t here — the ongoing loop is continuous
				# across cycles, which is the whole point of "already happening".
				_reset_shown_flags()
				_pv_phase = 1
		1:  # IN
			_anim_t += delta
			if run_ongoing: _loop_t += delta
			if _anim_t >= _full_duration(in_duration):
				_anim_t = 0.0; _pv_acc = 0.0; _pv_phase = 2
		2:  # HOLD
			_loop_t += delta
			if _pv_acc >= preview_hold:
				_pv_acc = 0.0; _anim_t = 0.0; _pv_phase = 3
		3:  # OUT
			_anim_t += delta
			if ongoing_during_out and run_ongoing: _loop_t += delta
			if _anim_t >= _full_duration(out_duration):
				_anim_t = 0.0; _pv_acc = 0.0; _pv_phase = 0
	queue_redraw()
