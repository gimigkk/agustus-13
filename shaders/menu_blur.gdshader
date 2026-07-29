shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius : hint_range(0.0, 30.0) = 4.0;
uniform vec4 dim_color : source_color = vec4(0.0, 0.0, 0.0, 0.6);

void fragment() {
	vec2 uv = SCREEN_UV;
	
	if (blur_radius <= 0.05) {
		vec4 col = textureLod(screen_texture, uv, 0.0);
		COLOR = vec4(mix(col.rgb, dim_color.rgb, dim_color.a), 1.0) * vec4(1.0, 1.0, 1.0, COLOR.a);
	} else {
		// Dynamic hardware Mipmap LOD sampling
		float lod = clamp(blur_radius * 0.35, 0.0, 4.5);
		vec2 size = SCREEN_PIXEL_SIZE * (1.0 + lod * 1.5);
		
		// Fast 3x3 Gaussian kernel (9 samples instead of 49)
		vec4 col = vec4(0.0);
		float total_weight = 0.0;
		
		for (float x = -1.0; x <= 1.0; x += 1.0) {
			for (float y = -1.0; y <= 1.0; y += 1.0) {
				float weight = (x == 0.0 && y == 0.0) ? 4.0 : ((x == 0.0 || y == 0.0) ? 2.0 : 1.0);
				col += textureLod(screen_texture, uv + vec2(x, y) * size, lod) * weight;
				total_weight += weight;
			}
		}
		
		col /= total_weight;
		COLOR = vec4(mix(col.rgb, dim_color.rgb, dim_color.a), 1.0) * vec4(1.0, 1.0, 1.0, COLOR.a);
	}
}
