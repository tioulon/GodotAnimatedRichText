## demo.gd — AnimatedRichLabel showcase.
## Attach to a Control filling a 640×360 viewport.
extends Control

var _labels: Array[AnimatedRichLabel] = []
var _version := 0

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.11)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_make_demos()
	_start(_version)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_R:
		_restart()

func _make_demos() -> void:
	# Each entry: position, bbcode text, in, out, ongoing[], extras
	var rainbow := OnRainbow.new()
	var wave := OnWave.new(); wave.amplitude = 2.5; wave.speed = 3.0

	# 1 — Typewriter dialog with built-in theme outline (per-char outline)
	var l1 := _spawn(Vector2(40, 60),
		"[b]Hero:[/b] It's dangerous to go alone!",
		InTypewriter.new(), OutFade.new(), [])
	OutlineHelper.apply_theme(l1, Color.BLACK, 4)
	l1.stagger_delay = 0.035
	l1.in_duration = 0.05

	# 2 — Wave-in + rainbow + wave-bob, with the UNIFIED outline shader (two-tone top)
	var l2 := _spawn(Vector2(40, 120),
		"[b]RAINBOW QUEST[/b]",
		InWave.new(), OutScale.new(), [rainbow, wave])
	OutlineHelper.apply(l2, {
		"thickness": 3.0, "color": Color.BLACK,
		"top_color": Color(1, 1, 1, 0.9), "top_height": 1.0,
	})
	l2.add_theme_font_size_override("normal_font_size", 28)

	# 3 — Scale-in + pulse
	var l3 := _spawn(Vector2(40, 185),
		"x3 [color=gold]COMBO![/color]",
		InScale.new(), OutBounce.new(), [_pulse()])

	# 4 — Dissolve + jitter (CRT)
	var dissolve := InDissolve.new(); dissolve.flash = true
	var l4 := _spawn(Vector2(40, 240),
		"[color=#33ff88]> INITIALIZING SYSTEM...[/color]",
		dissolve, OutFade.new(), [_jitter()])
	l4.stagger_delay = 0.0
	l4.in_duration = 0.9

	# 5 — Spin-in + wobble
	var l5 := _spawn(Vector2(380, 185),
		"[color=#ff6060][b]CRITICAL![/b][/color]",
		InSpin.new(), OutSlide.new(), [_wobble()])

	# 6 — NEW: Swirl-in mixed with continuous orbit + sparkle (loop runs during entrance)
	var swirl := InSwirl.new(); swirl.radius = 24.0; swirl.spins = 1.0
	var orbit := OnOrbit.new(); orbit.radius = 1.5; orbit.speed = 1.0
	var sparkle := OnSparkle.new()
	var l6 := _spawn(Vector2(40, 300),
		"[color=#ffd24a]✦ Legendary Loot ✦[/color]",
		swirl, OutScale.new(), [orbit, sparkle])
	l6.add_theme_font_size_override("normal_font_size", 20)

	# 7 — NEW: Glitch-in + flicker (sci-fi)
	var glitch := InGlitch.new()
	var flicker := OnFlicker.new()
	var l7 := _spawn(Vector2(380, 300),
		"[color=#3affd2]ACCESS GRANTED[/color]",
		glitch, OutFade.new(), [flicker])

func _pulse() -> OnPulse:
	var p := OnPulse.new(); p.scale_amount = 0.14; p.frequency = 2.0; return p
func _jitter() -> OnJitter:
	var j := OnJitter.new(); j.amplitude = 1.0; j.rate = 8.0; return j
func _wobble() -> OnWobble:
	var w := OnWobble.new(); w.angle = 7.0; w.breathe = true; return w

func _spawn(pos: Vector2, txt: String, ina: InAnimation,
		outa: OutAnimation, ong: Array) -> AnimatedRichLabel:
	var l := AnimatedRichLabel.new()
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.position = pos
	l.custom_minimum_size = Vector2(560, 40)
	l.animated_text = txt
	l.in_animation = ina
	l.out_animation = outa
	l.ongoing_animations.assign(ong)
	l.auto_play = false
	l.add_theme_font_size_override("normal_font_size", 18)
	add_child(l)
	_labels.append(l)
	return l

func _start(v: int) -> void:
	for i in _labels.size():
		_loop(_labels[i], i * 0.3, v)

func _restart() -> void:
	_version += 1
	for l in _labels:
		l.stop(); l.hide_now()
	_start(_version)

func _loop(l: AnimatedRichLabel, delay: float, v: int) -> void:
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	while _version == v and is_instance_valid(l):
		l.play_in()
		await l.in_finished
		if _version != v: return
		await get_tree().create_timer(3.0).timeout
		if _version != v: return
		l.play_out()
		await l.out_finished
		if _version != v: return
		await get_tree().create_timer(0.4).timeout
