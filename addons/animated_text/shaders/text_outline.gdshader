// text_outline.gdshader  —  Godot 4.6
// ─────────────────────────────────────────────────────────────────────────
// Port of the GameMaker draw_text_outline(), as a canvas_item shader:
//   • 4-direction ring      → out_color           (the outline)
//   • dark bottom underside → bottom_color        (the "0" stamps below)
//   • the glyph itself       → drawn on top
//   • optional RAINBOW top edge, and pixel-perfect via pixel_size
//
// WHERE TO USE IT (important):
//   This shader samples a few texels AROUND each pixel, so it needs room to
//   draw the outline. Apply it to a TextureRect or Sprite2D whose texture has
//   a transparent MARGIN around the text (a few px of empty space). On
//   TextureRect set Stretch Mode = Keep and add padding, or bake the text to a
//   texture with padding. (Plain Label/RichTextLabel clip fragment shaders to
//   their rect — a Godot engine limitation #7553 — so use a TextureRect/Sprite,
//   or a SubViewport texture, as the surface.)
//
// The `margin` uniform insets the area the outline is allowed to grow into, so
// even a tightly-cropped texture won't show a hard cut — set it to your
// outline thickness in px.
// ─────────────────────────────────────────────────────────────────────────
shader_type canvas_item;
render_mode unshaded;

uniform float pixel_size : hint_range(1.0, 16.0, 1.0) = 1.0;
uniform int   thickness  : hint_range(1, 16, 1) = 1;

uniform vec4  out_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform bool  bottom_enabled = true;
uniform vec4  bottom_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int   bottom_depth : hint_range(1, 16, 1) = 2;

uniform bool  top_rainbow = false;
uniform float rainbow_speed : hint_range(0.0, 5.0, 0.05) = 1.0;
uniform float rainbow_scale : hint_range(0.1, 8.0, 0.1) = 1.0;

float a_at(sampler2D tex, vec2 uv, vec2 tpx) {
	// Stay inside the texture so we never read clamped/garbage edge texels.
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return 0.0;
	if (pixel_size > 1.0) {
		vec2 g = tpx * pixel_size;
		uv = (floor(uv / g) + 0.5) * g;
	}
	return texture(tex, uv).a;
}

vec3 hsv(float h) {
	return clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
}

void fragment() {
	vec2 tpx = TEXTURE_PIXEL_SIZE;
	vec4 src = texture(TEXTURE, UV);

	if (src.a > 0.5) {
		// The glyph — drawn as-is, on top.
		COLOR = src;
	} else {
		vec4 col = vec4(0.0);

		// ---- BOTTOM underside ----
		if (bottom_enabled) {
			bool hit = false;
			for (int d = 1; d <= bottom_depth; d++) {
				float yy = float(d) * pixel_size;
				float tx = float(thickness) * pixel_size;
				if (a_at(TEXTURE, UV + vec2(0.0, -yy), tpx) > 0.5 ||
					a_at(TEXTURE, UV + vec2(-tx, -yy), tpx) > 0.5 ||
					a_at(TEXTURE, UV + vec2( tx, -yy), tpx) > 0.5) {
					hit = true; break;
				}
			}
			if (hit) col = bottom_color;
		}

		// ---- 4-DIR OUTLINE ----
		bool is_out = false;
		bool from_above = false;   // glyph below us → we are on the TOP edge
		for (int t = 1; t <= thickness; t++) {
			float s = float(t) * pixel_size;
			float up    = a_at(TEXTURE, UV + vec2(0.0,  s), tpx);
			float down  = a_at(TEXTURE, UV + vec2(0.0, -s), tpx);
			float left  = a_at(TEXTURE, UV + vec2( s, 0.0), tpx);
			float right = a_at(TEXTURE, UV + vec2(-s, 0.0), tpx);
			if (up > 0.5 || down > 0.5 || left > 0.5 || right > 0.5) {
				is_out = true;
				if (up > 0.5) from_above = true;
				break;
			}
		}

		if (is_out) {
			vec4 oc = out_color;
			if (top_rainbow && from_above) {
				oc.rgb = hsv(fract(UV.x * rainbow_scale + TIME * rainbow_speed));
				oc.a = out_color.a;
			}
			col = mix(col, oc, oc.a);
			col.a = max(col.a, oc.a);
		}

		COLOR = col;
	}
}
