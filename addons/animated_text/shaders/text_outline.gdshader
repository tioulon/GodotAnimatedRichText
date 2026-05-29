// text_outline.gdshader  —  Godot 4.6
// Two-tone pixel-perfect text outline + drop shadow.
// Apply as a ShaderMaterial on the AnimatedRichLabel (node sets clip_contents=false).
// Give the node a little extra size so the outline has room.
shader_type canvas_item;
render_mode unshaded;

uniform bool  outline_enabled = true;
uniform vec4  outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness : hint_range(0.0, 64.0, 1.0) = 4.0;
uniform float pixel_size : hint_range(1.0, 16.0, 1.0) = 1.0;
uniform int   quality : hint_range(4, 32, 1) = 16;

uniform bool  top_enabled = false;
uniform vec4  top_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float top_height : hint_range(0.0, 64.0, 1.0) = 2.0;

uniform bool  shadow_enabled = false;
uniform vec4  shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform vec2  shadow_offset = vec2(2.0, 2.0);

const float PI2 = 6.28318530718;

// TEXTURE can only be read inside fragment(), so the sampler is passed in.
float src_a(sampler2D tex, vec2 uv, vec2 tpx) {
	if (pixel_size > 1.0) {
		vec2 g = tpx * pixel_size;
		uv = (floor(uv / g) + 0.5) * g;
	}
	return texture(tex, uv).a;
}

void fragment() {
	vec2 tpx = TEXTURE_PIXEL_SIZE;
	vec4 src = texture(TEXTURE, UV);
	vec4 col = src;
	bool is_glyph = src.a > 0.5;

	if (!is_glyph) {
		if (shadow_enabled) {
			if (src_a(TEXTURE, UV - shadow_offset * tpx, tpx) > 0.5) {
				col = shadow_color;
			}
		}
		if (outline_enabled && outline_thickness > 0.0) {
			float best = 1e9;
			float best_dy = 0.0;
			int steps = int(ceil(outline_thickness / max(pixel_size, 1.0)));
			steps = max(steps, 1);
			for (int i = 0; i < quality; i++) {
				float a = (float(i) / float(quality)) * PI2;
				vec2 dir = vec2(cos(a), sin(a));
				for (int s = 1; s <= steps; s++) {
					float dist = float(s) * pixel_size;
					if (dist > outline_thickness) break;
					if (src_a(TEXTURE, UV + dir * tpx * dist, tpx) > 0.5) {
						if (dist < best) { best = dist; best_dy = dir.y; }
						break;
					}
				}
			}
			if (best <= outline_thickness) {
				vec4 oc = outline_color;
				if (top_enabled && best_dy > 0.20) {
					float from_outer = outline_thickness - best;
					if (from_outer <= top_height) {
						oc = top_color;
					}
				}
				col = mix(col, oc, oc.a);
				col.a = max(col.a, oc.a);
			}
		}
	}
	if (is_glyph) {
		col = src;
	}
	COLOR = col;
}
