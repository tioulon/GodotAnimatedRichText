# AnimatedText

**Per-character animated text for Godot 4, built on top of `RichTextLabel`.**

Because the node *is* a `RichTextLabel`, you keep everything you already know —
fonts, theme overrides, full BBCode, wrapping, alignment — and gain layered
**entrance, exit, and continuous** per-character animations on top.

```gdscript
var label := AnimatedRichLabel.new()
label.animated_text = "Hello, [b]World[/b]!"
label.in_animation = InWave.new()
label.ongoing_animations = [OnRainbow.new()]
add_child(label)
label.play_in()
```

---

## Features

- **Three separate animation layers** — `in`, `out`, and stackable `ongoing`.
- **50 built-in animations** — 21 entrances, 8 exits, 21 continuous effects.
- **Built on RichTextLabel** — all theme overrides + full BBCode work inside the text.
- **Translatable** — text runs through `tr()`, and all custom tags are parsed *after* translation.
- **Inline `[wait=0.5]`** — direction-aware typewriter pauses.
- **Region tags** — scope an ongoing effect to part of the text with a custom BBCode tag.
- **Independent in/out direction** — left-to-right, right-to-left, center-out, edges-in, random.
- **22 easing types** + optional custom `Curve` per animation.
- **Live editor preview** — see the full in → hold → out loop without running the game.
- **Efficient** — uses RichTextLabel's native per-glyph effect path; no node-per-character, no per-frame allocations.

---

## Installation

1. Copy the `addons/animated_text/` folder into your project.
2. **Project → Project Settings → Plugins →** enable **AnimatedText**.
3. Add an **AnimatedRichLabel** node from the Create Node dialog.

To try the included demo, open the project and run it (640×360, cycles through
all animation styles; press **R** to restart).

> Tip: if you ever see stale class/UID errors after updating, close Godot,
> delete the project's `.godot/` folder, and reopen — it regenerates the cache.

---

## Quick start (inspector)

1. Add an **AnimatedRichLabel**.
2. Set **Animated Text** (supports BBCode).
3. Under **In Animation**, create a new resource — e.g. `InWave`.
4. Tick **Editor Preview** to watch it loop live, or run the scene.

## Quick start (code)

```gdscript
var l := AnimatedRichLabel.new()
l.animated_text = "Press [b]A[/b] to continue..."
l.in_animation   = InTypewriter.new()
l.out_animation  = OutFade.new()
l.ongoing_animations = [OnWave.new()]
l.stagger_delay  = 0.04
add_child(l)

l.play_in()
await l.in_finished
# ...later...
l.play_out()
await l.out_finished
```

---

## Animations

All animations are `Resource`s you assign in the inspector or create in code
(`InWave.new()`, etc.). Each in/out animation has an **easing** dropdown and an
optional custom **curve**.

### In (21)
`InFade` · `InTypewriter` · `InSlide` · `InScale` · `InSpin` · `InWave` ·
`InBounce` · `InDissolve` · `InGlitch` · `InDrop` · `InUnfold` · `InSwirl` ·
`InStretch` · `InStandUp` · `InZoom` · `InPopColor` · `InPendulum` · `InSquash` · `InFlip3D` · `InCascade` · `InBlurZoom`

### Out (8)
`OutFade` · `OutSlide` · `OutScale` · `OutBounce` · `OutTypewriter` · `OutSpin` · `OutDissolve` · `OutDrop`

### Ongoing (21, stackable)
`OnWave` · `OnShake` · `OnPulse` · `OnRainbow` · `OnFloat` · `OnJitter` ·
`OnWobble` · `OnBreathe` · `OnFlicker` · `OnOrbit` · `OnSparkle` · `OnBounce` ·
`OnSway` · `OnTremor` · `OnColorCycle` · `OnSolidColor` · `OnHeartbeat` · `OnSwing` · `OnVibrate` · `OnGlow` · `OnMarquee`

Ongoing effects are applied additively — stack as many as you like. By default
they also blend *into* the entrance, as if the loop were already playing when
the text appears (toggle with `ongoing_during_in`).

### Reusable ongoing sets
Build a set of ongoing effects once and share it across many nodes: create an
**OngoingAnimationSet** resource (`.tres`), fill its `animations` array, and
assign it to a node's **`ongoing_set`** property. The node merges the set with
its own inline `ongoing_animations`, so you get a shared base plus per-node
extras. Editing the `.tres` updates every node that uses it.

`OnColorCycle` takes an **array of colors** (`colors`) and walks through them
all, looping seamlessly; `OnSolidColor` applies one flat (optionally pulsing)
color.

---

## Inline tags

These are parsed **after** `tr()`, so they work with translation keys. Real
BBCode (`[b]`, `[color]`, Godot's own `[wave]`, …) passes through untouched.

### `[wait=seconds]` — typewriter pause
Pauses the reveal at that point in the text. It is **direction-aware**:

```
"Hello, [wait=0.4]World!"
```
- Left-to-right: `Hello,` appears → 0.4s pause → `World!`
- Right-to-left: `World!` appears → 0.4s pause → `Hello,`

Waits apply only to `LEFT_TO_RIGHT` / `RIGHT_TO_LEFT` in-stagger (ignored for
other staggers and for the out animation).

### Region tags — scope an ongoing effect
Give an ongoing animation a `bbcode_tag` (e.g. `g`), then wrap part of the text:

```gdscript
var rb := OnRainbow.new()
rb.bbcode_tag = "g"
label.ongoing_animations = [OnWave.new(), rb]   # wave everywhere, rainbow only in [g]
label.animated_text = "Press [g]START[/g] now"
```

The tagged effect applies only inside its region and still mixes with the
untagged (global) ones. Choose a tag name that doesn't clash with real BBCode
(`b`, `i`, `color`, `wave`, …).

---

## API

```gdscript
play_in()              # entrance
play_out()             # exit
show_now()             # snap visible (ongoing keeps running)
hide_now()             # snap hidden
stop()                 # freeze
restart_ongoing()      # reset the loop clock

is_playing_in() -> bool
is_playing_out() -> bool
is_holding() -> bool
glyph_count() -> int
```

**Signals:** `in_finished`, `out_finished`, `char_shown(visible_index)`.

### Key properties

| Property | Description |
|---|---|
| `animated_text` | The text (BBCode + inline tags supported). |
| `in_animation` / `out_animation` | Entrance / exit resource. |
| `ongoing_animations` | `Array[OngoingAnimation]`, stacked additively. |
| `in_duration` / `out_duration` | Per-glyph animation length. |
| `stagger_delay` | Seconds between consecutive glyphs (the wave reveal). |
| `in_stagger` / `out_stagger` | Direction each phase reveals in. |
| `auto_play` | Play the entrance on entering the tree. |
| `skip_in_animation` | Appear instantly; only ongoing plays (overrides `hide_until_started`). |
| `run_ongoing` | Master switch for ongoing effects. |
| `ongoing_during_in` / `ongoing_during_out` | Blend the loop into the entrance / exit. |
| `hide_until_started` | Keep glyphs invisible until their stagger window opens. |
| `preview` / `preview_hold` | Live editor preview of the full cycle. |

### Stagger directions
`LEFT_TO_RIGHT` · `RIGHT_TO_LEFT` · `CENTER_OUT` · `EDGES_IN` · `RANDOM`

---

## Custom animations

Extend a base class and override `apply()`:

```gdscript
@tool
class_name InFlash
extends InAnimation

@export var flash_color := Color.YELLOW

func apply(mod: CharMod, t: float, idx: int, total: int) -> void:
    mod.alpha = eased(t)                         # eased() uses easing/curve
    mod.color = flash_color.lerp(Color.WHITE, t)
```

`CharMod` fields: `offset: Vector2`, `scale: Vector2`, `rotation: float`,
`color: Color`, `alpha: float`, `pivot: Vector2`.

Helpers on In/Out: `eased(t)` (applies the easing/curve), `sub(t, from, to)`
(remap a sub-range to 0–1). Ongoing animations get continuous `time` instead of
a normalized `t`, plus a `strength` multiplier and optional `bbcode_tag`.

---

## Outlines

Outlines are intentionally **not** part of the node. Godot clips canvas-item
shaders and theme outlines to a node's rect, so a per-character animated outline
can't expand cleanly on a live `RichTextLabel` (engine limitation, see
proposals #7553 / #105432).

For when you do want one, `shaders/text_outline.gdshader` is included — a port
of the classic GameMaker `draw_text_outline` (4-direction outline + dark
underside + optional rainbow top, pixel-perfect). It's a standalone
`canvas_item` shader meant for a `TextureRect`/`Sprite2D` (a surface that *can*
draw past its bounds). See `shaders/USAGE_text_outline.md`.

For a simple in-text outline that never clips, use Godot's built-in theme
outline (`font_outline_color` + `outline_size`) — single color, drawn per glyph
by the engine.

---

## Notes

- **Pixel art:** use a bitmap/pixel font with antialiasing off; whole-pixel
  offset values keep things crisp.
- **Performance:** animation runs through RichTextLabel's native effect path,
  with pooled scratch objects — no node-per-character, no per-frame allocations.
- **Don't nest other custom `RichTextEffect`s** inside the text — this addon
  already wraps the whole text in one effect. Plain formatting BBCode is fine.

## License

MIT — free for personal and commercial use.
