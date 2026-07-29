shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 0.0;
uniform float padding_scale : hint_range(1.0, 2.0) = 1.15;

void fragment() {
	vec4 col = vec4(0.0);
	float total = 0.0;
	vec2 ps = TEXTURE_PIXEL_SIZE;
	
	vec2 center = vec2(0.5, 0.5);
	vec2 padded_uv = (UV - center) * padding_scale + center;
	
	for(float x = -2.0; x <= 2.0; x++) {
		for(float y = -2.0; y <= 2.0; y++) {
			float w = exp(-(x*x + y*y) / 4.0);
			vec2 sample_uv = padded_uv + vec2(x, y) * ps * blur_amount;
			
			if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
				col += texture(TEXTURE, sample_uv) * w;
			}
			total += w;
		}
	}
	col /= total;
	COLOR = vec4(0.0, 0.0, 0.0, col.a * COLOR.a);
}
