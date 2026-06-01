# text_outline.gdshader — usage

A canvas_item shader port of the GameMaker `draw_text_outline()`:
4-direction outline (`out_color`) + dark bottom underside (`bottom_color`) +
the glyph on top. Optional rainbow top edge. Pixel-perfect via `pixel_size`.

## Important: where shaders are allowed to draw

A canvas_item fragment shader can only draw **inside the node's rectangle**
(Godot limitation — proposal #7553). So the surface must have room around the
text. Two reliable surfaces:

### TextureRect (or Sprite2D)
1. Get the text as a texture **with a transparent margin** (a few px of empty
   space on all sides). Easiest: bake your text once, or use a texture that
   already has padding.
2. Put the texture on a `TextureRect`, `Stretch Mode = Keep`.
3. Add the `ShaderMaterial` with this shader.
4. Set `margin`/`thickness` ≤ the padding so the outline isn't cut.

### SubViewport surface (if you don't want to bake a texture)
Render your label into a `SubViewport` (transparent_bg = true) sized with
padding, then show `SubViewport.get_texture()` on a `TextureRect` with this
shader. (This is the only way to outline a live RichTextLabel without clipping,
because the label itself clips fragment shaders to its rect.)

## Parameters
- `pixel_size` — texels per "pixel"; scales the outline and quantizes sampling
  for a crisp pixel-art look (1, 2, 3…).
- `thickness` — how many pixel-steps the 4-dir ring extends (1 = original).
- `out_color` — outline color.
- `bottom_enabled` / `bottom_color` / `bottom_depth` — the dark underside.
- `top_rainbow` / `rainbow_speed` / `rainbow_scale` — rainbow on the TOP edge.
