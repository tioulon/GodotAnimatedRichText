## AnimatedRichLabel — animated text built ON TOP of RichTextLabel.
##
## Because this IS a RichTextLabel, you get every feature for free:
##   - All theme overrides (font, font_size, colors, outline, shadow, spacing)
##   - Full BBCode (bold, italics, color, font, img, tables, etc.)
##   - Text wrapping, alignment, scrolling, fit-content, etc.
##
## On top of that it adds per-character entrance / exit / ongoing animations.
##
## ANIMATION SLOTS (kept separate to avoid confusion):
##   in_animation        - InAnimation        plays once on play_in()
##   out_animation       - OutAnimation       plays once on play_out()
##   ongoing_animations  - Array of OngoingAnimation, loop continuously, stackable
##
## CUSTOM INLINE TAGS (parsed AFTER tr, so fully translatable):
##   wait=0.5    pause the reveal 0.5s at this point (direction-aware)
##   region tag  scope an ongoing animation to a region by setting its
##               bbcode_tag, then wrapping that part of the text in the tag.
##
## HOW IT WORKS
##   The label wraps its whole text in a custom RichTextEffect. Godot calls back
##   per glyph per frame; we apply a precomputed transform. This is the native,
##   efficient path RichTextLabel uses for its own glyph effects.
##
## QUICK START
##   var l := AnimatedRichLabel.new()
##   l.animated_text = "Hello world!"
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
## A reusable set of ongoing effects (a saved .tres you can share across nodes).
## Merged with the inline `ongoing_animations` below — set provides the shared
## base, inline adds per-node extras.
@export var ongoing_set: OngoingAnimationSet:
	set(v):
		ongoing_set = v
		_rebuild_ongoing()
## Stackable continuous effects on THIS node (applied additively, in order).
@export var ongoing_animations: Array[OngoingAnimation] = []:
	set(v):
		ongoing_animations = v
		_rebuild_ongoing()

# ═══════════════════════════════════════════════════════════════════
# Exports — Timing
# ═══════════════════════════════════════════════════════════════════
@export_group("Timing")
## Seconds between consecutive glyphs starting their in/out animation.
## This is what creates the staggered, one-after-another reveal. Set to 0 for
## all glyphs at once; higher = slower wave across the text.
@export var stagger_delay: float = 0.04
## Duration of each glyph's in-animation.
@export var in_duration: float = 0.35
## Duration of each glyph's out-animation.
@export var out_duration: float = 0.28
## Order/direction glyphs animate IN.
@export var in_stagger: Stagger = Stagger.LEFT_TO_RIGHT:
	set(v): in_stagger = v; _orders_dirty = true
## Order/direction glyphs animate OUT.
@export var out_stagger: Stagger = Stagger.LEFT_TO_RIGHT:
	set(v): out_stagger = v; _orders_dirty = true
## Seed for RANDOM stagger (change for a different shuffle).
@export var random_seed: int = 0

# ═══════════════════════════════════════════════════════════════════
# Exports — Behavior
# ═══════════════════════════════════════════════════════════════════
@export_group("Behavior")
## Play the in-animation automatically when entering the tree.
@export var auto_play: bool = true
## Skip the in-animation entirely: the text appears immediately at rest and only
## the ongoing animations play. Applies to both auto_play and play_in().
@export var skip_in_animation: bool = false
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
var _order_in: PackedInt32Array = PackedInt32Array()    # glyph idx → in stagger rank
var _order_out: PackedInt32Array = PackedInt32Array()   # glyph idx → out stagger rank
var _orders_dirty: bool = false
var _shown_flags: PackedByteArray = PackedByteArray()

## Custom-tag regions: { "g": [{start, end}, ...] } in visible char indices.
var _tag_ranges: Dictionary = {}
## Per-character extra typewriter delay from [wait=N]: { char_index: seconds }.
var _wait_at: Dictionary = {}
## Cumulative wait before each glyph, in stagger-rank order, per direction.
var _wait_cumulative_in: PackedFloat32Array = PackedFloat32Array()
var _wait_cumulative_out: PackedFloat32Array = PackedFloat32Array()

# Pooled scratch objects — zero allocation in the per-glyph hot path
var _mod: CharMod = CharMod.new()
var _tmp: CharMod = CharMod.new()

## Merged list of ongoing animations (ongoing_set.animations + ongoing_animations).
var _ongoing: Array[OngoingAnimation] = []

## Rebuild the merged ongoing list from the shared set + the inline array.
func _rebuild_ongoing() -> void:
	_ongoing.clear()
	if ongoing_set and ongoing_set.animations:
		for a in ongoing_set.animations:
			if a: _ongoing.append(a)
	for a in ongoing_animations:
		if a: _ongoing.append(a)

## Editor-only signature of everything that affects the merged list and tag
## parsing. When it changes, we rebuild + rewrap. Cheap to compute each frame.
var _editor_sig: String = ""

func _build_editor_sig() -> String:
	var parts := PackedStringArray()
	parts.append(animated_text)
	parts.append(str(in_stagger) + "," + str(out_stagger))
	# include the set + inline animations: identity, tag, strength
	var lists := [ongoing_set.animations if ongoing_set else [], ongoing_animations]
	for lst in lists:
		for a in lst:
			if a:
				parts.append("%d|%s|%s" % [a.get_instance_id(), a.bbcode_tag, str(a.strength)])
			else:
				parts.append("nil")
	return "\u0001".join(parts)

## Called every editor frame: refresh only when something actually changed.
func _editor_live_refresh() -> void:
	var sig := _build_editor_sig()
	if sig != _editor_sig:
		_editor_sig = sig
		_rebuild_ongoing()
		_rewrap()          # re-parses tags + waits and re-wraps the text
		queue_redraw()

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
	_rebuild_ongoing()
	_rewrap()

	if Engine.is_editor_hint():
		if preview: _preview_reset()
		return

	if auto_play:
		play_in()
	else:
		_phase = Phase.IDLE
		# skip_in_animation overrides hide_until_started: there's no entrance to
		# wait for, so the text should be visible (only ongoing will run).
		if hide_until_started and not skip_in_animation:
			_hidden = true
			modulate.a = 0.0   # reliable hide before the first effect frame
		queue_redraw()

## Re-applies the effect whenever the node (re)enters the tree.
## Fixes the editor losing the effect after closing/reopening the scene.
func _enter_tree() -> void:
	if _ready_done:
		_install_effect()
		_rebuild_ongoing()
		_rewrap_needed = true

func _install_effect() -> void:
	# Reuse an existing ATGlyphEffect if one was serialized with the scene
	# (avoids duplicates on editor reload) and reconnect its label reference.
	var fx: Array = []
	var found := false
	for e in custom_effects:
		if e is ATGlyphEffect:
			if found:
				continue   # drop any duplicates
			_effect = e
			_effect.label = self
			found = true
			fx.append(_effect)
		else:
			fx.append(e)   # keep unrelated effects
	if not found:
		_effect = ATGlyphEffect.new()
		_effect.label = self
		fx.append(_effect)
	custom_effects = fx

func _process(delta: float) -> void:
	if _rewrap_needed:
		_rewrap()
	if _orders_dirty and _total > 0:
		_build_order()

	if Engine.is_editor_hint():
		# Sub-resources (the ongoing set, an animation's bbcode_tag, etc.) can be
		# edited without firing this node's setters, leaving us stale. Cheaply
		# detect such changes each editor frame and refresh only when needed.
		_editor_live_refresh()
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
			needs_redraw = run_ongoing and _ongoing.size() > 0
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
	modulate.a = 1.0   # undo the hide_until_started pre-hide
	if skip_in_animation:
		# No entrance: jump straight to the resting/holding state, ongoing only.
		_anim_t = 0.0
		_loop_t = 0.0
		_phase  = Phase.HOLD if (run_ongoing and _ongoing.size() > 0) else Phase.IDLE
		in_finished.emit()
		queue_redraw()
		return
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
	modulate.a = 1.0
	_anim_t = 0.0
	_loop_t = 0.0
	_phase  = Phase.HOLD if (run_ongoing and _ongoing.size() > 0) else Phase.IDLE
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

	# Translate first, THEN parse our custom tags so everything is translatable.
	var translated := tr(animated_text)
	var clean := _parse_custom_tags(translated)

	# Wrap the cleaned text (which still contains real BBCode) in our effect tag.
	text = "[animated_text]" + clean + "[/animated_text]"
	_total = get_total_character_count()
	_build_order()
	_reset_shown_flags()

## Parse OUR custom tags out of the text, recording per-character data, and
## return the text with only real BBCode left (which RichTextLabel renders).
##
## Handles:
##   • animation scope tags  [g]...[/g]  → _tag_ranges["g"] = [{start,end}, ...]
##   • wait delays           [wait=0.2]  → _wait_at[char_index] += 0.2
## Anything else in brackets (real BBCode like bold, color, wave) is kept.
func _parse_custom_tags(s: String) -> String:
	_tag_ranges.clear()
	_wait_at.clear()

	# Which tag names are "ours" (declared by ongoing animations)?
	var anim_tags := {}
	for a in _ongoing:
		if a and not a.bbcode_tag.is_empty():
			anim_tags[a.bbcode_tag] = true

	var open_stack := {}      # tag name → start char index (for nesting per tag)
	var out := ""
	var ci := 0               # visible character index in the CLEAN string
	var i := 0
	while i < s.length():
		var c := s[i]
		if c == "[":
			var close := s.find("]", i)
			if close != -1:
				var inner := s.substr(i + 1, close - i - 1)
				var handled := false

				# [wait=N]
				if inner.begins_with("wait="):
					var secs := inner.substr(5).to_float()
					_wait_at[ci] = _wait_at.get(ci, 0.0) + secs
					handled = true
				# [tag] / [/tag] for one of our animation tags
				elif anim_tags.has(inner):
					open_stack[inner] = ci
					handled = true
				elif inner.begins_with("/") and anim_tags.has(inner.substr(1)):
					var name := inner.substr(1)
					if open_stack.has(name):
						if not _tag_ranges.has(name):
							_tag_ranges[name] = []
						_tag_ranges[name].append({"start": open_stack[name], "end": ci})
						open_stack.erase(name)
					handled = true

				if handled:
					i = close + 1
					continue
				else:
					# Real BBCode — keep the whole tag verbatim, doesn't add a char.
					out += s.substr(i, close - i + 1)
					i = close + 1
					continue
		# Normal visible character.
		out += c
		ci += 1
		i += 1
	return out

## True if glyph `idx` is inside any region of the given tag.
func _idx_in_tag(idx: int, tag: String) -> bool:
	if not _tag_ranges.has(tag):
		return false
	for r in _tag_ranges[tag]:
		if idx >= r.start and idx < r.end:
			return true
	return false

func _build_order() -> void:
	_order_in = _make_order(in_stagger)
	_order_out = _make_order(out_stagger)
	_orders_dirty = false
	# Waits are direction-aware and only meaningful for the two reading-order
	# staggers (LEFT_TO_RIGHT / RIGHT_TO_LEFT). For any other stagger, or for
	# the out animation, waits are ignored (all zero).
	_wait_cumulative_in = _make_wait_cumulative(in_stagger)
	_wait_cumulative_out = PackedFloat32Array()
	_wait_cumulative_out.resize(_total)   # out: always zero (no waits on exit)

## Build per-glyph cumulative wait (seconds) for a stagger direction.
##
## A [wait=N] sits at a text BOUNDARY (between char b-1 and char b). It pauses
## the reveal at that point in the TEXT, delaying whichever side animates later:
##   • LEFT_TO_RIGHT : glyphs at index >= boundary are delayed (text after).
##   • RIGHT_TO_LEFT : glyphs at index <  boundary are delayed (text before).
##   • anything else : waits don't apply (returns all zeros).
func _make_wait_cumulative(mode: Stagger) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	result.resize(_total)
	if _total == 0 or _wait_at.is_empty():
		return result
	if mode != Stagger.LEFT_TO_RIGHT and mode != Stagger.RIGHT_TO_LEFT:
		return result   # waits only make sense for reading-order reveals

	# Sorted boundary positions and their delays.
	var boundaries := _wait_at.keys()
	boundaries.sort()

	if mode == Stagger.LEFT_TO_RIGHT:
		# Each glyph i is delayed by the sum of all waits whose boundary <= i.
		for i in _total:
			var d := 0.0
			for b in boundaries:
				if b <= i:
					d += _wait_at[b]
			result[i] = d
	else:  # RIGHT_TO_LEFT
		# Each glyph i is delayed by the sum of all waits whose boundary > i
		# (those boundaries are reached earlier in the right-to-left sweep).
		for i in _total:
			var d := 0.0
			for b in boundaries:
				if b > i:
					d += _wait_at[b]
			result[i] = d
	return result

## Produce a glyph-index → stagger-rank mapping for a given direction.
func _make_order(mode: Stagger) -> PackedInt32Array:
	var order := PackedInt32Array()
	order.resize(_total)
	match mode:
		Stagger.LEFT_TO_RIGHT:
			for i in _total: order[i] = i
		Stagger.RIGHT_TO_LEFT:
			for i in _total: order[i] = _total - 1 - i
		Stagger.CENTER_OUT:
			var c := (_total - 1) * 0.5
			for i in _total: order[i] = int(absf(i - c) * 2.0)
		Stagger.EDGES_IN:
			var c := (_total - 1) * 0.5
			for i in _total: order[i] = int(c - absf(i - c))
		Stagger.RANDOM:
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(str(random_seed) + animated_text + str(mode))
			var arr: Array[int] = Array(range(_total), TYPE_INT, "", null)
			for i in range(_total - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var t: int = arr[i]; arr[i] = arr[j]; arr[j] = t
			for i in _total: order[i] = arr[i]
	return order

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
	_compute_mod(m, idx)
	_write_to_transform(ch, m)
	return true

## Compute the per-glyph CharMod for the given index in the current phase.
## Shared by the RichTextEffect path and the custom-draw path.
func _compute_mod(m: CharMod, idx: int) -> void:
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
			if _hidden:
				m.alpha = 0.0
			elif run_ongoing and _ongoing.size() > 0:
				_compute_ongoing(m, idx)


func _compute_in(m: CharMod, idx: int) -> void:
	var t := _glyph_t(idx, in_duration)

	# Glyph hasn't started its entrance yet.
	if t <= 0.0:
		if ongoing_during_in and run_ongoing and _ongoing.size() > 0:
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
	if run_ongoing and _ongoing.size() > 0:
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
	if ongoing_during_out and run_ongoing and _ongoing.size() > 0:
		_compute_ongoing(m, idx)

func _compute_ongoing(m: CharMod, idx: int) -> void:
	for anim in _ongoing:
		if anim and anim.strength > 0.0:
			# Region scoping: if this animation has a tag, only apply it to
			# glyphs inside that [tag]...[/tag] region.
			if not anim.bbcode_tag.is_empty() and not _idx_in_tag(idx, anim.bbcode_tag):
				continue
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
	# Runs for the main pass AND the outline pass (ch.outline), so the native
	# outline inherits the same fade/tint automatically.
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
	# Pick the order + wait table for the active phase.
	var ap := _pv_to_phase() if (Engine.is_editor_hint() and preview) else _phase
	var is_out := ap == Phase.OUT
	var order := _order_out if is_out else _order_in
	var waits := _wait_cumulative_out if is_out else _wait_cumulative_in
	var rank := order[idx] if idx < order.size() else idx
	var wait := waits[idx] if idx < waits.size() else 0.0
	var start := rank * stagger_delay + wait
	return clampf((_anim_t - start) / duration, 0.0, 1.0)

func _full_duration(per_glyph: float) -> float:
	if _total <= 0: return 0.0
	# Add the largest cumulative wait for the relevant phase. Out has no waits.
	var max_wait := 0.0
	var table := _wait_cumulative_in if per_glyph == in_duration else _wait_cumulative_out
	for w in table:
		if w > max_wait: max_wait = w
	return per_glyph + stagger_delay * maxf(_total - 1, 0) + max_wait

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
