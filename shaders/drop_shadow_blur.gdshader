shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 30.0) = 14.0;
uniform float shadow_opacity : hint_range(0.0, 1.0) = 0.28;
uniform float radial_outward : hint_range(0.0, 0.1) = 0.035; // Outward X displacement from center
uniform float vertical_offset : hint_range(0.0, 30.0) = 10.0; // Downward Y displacement (px)

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// Smoothly fade out drop shadows above the well opening in open sky (Y <= -3850)
	float sky_fade = clamp((world_pos.y - (-3950.0)) / 100.0, 0.0, 1.0);
	if (sky_fade <= 0.001) {
		discard;
	}

	// Radial shadow offset: X offset expands outwards from center (UV.x = 0.5)
	vec2 offset_uv = vec2(
		(UV.x - 0.5) * radial_outward,
		TEXTURE_PIXEL_SIZE.y * vertical_offset
	);
	
	vec2 target_uv = UV - offset_uv;
	vec2 ps = TEXTURE_PIXEL_SIZE * blur_amount;
	
	// 25-sample deep Gaussian box blur for ultra-soft, feathered shadow edges
	float alpha = 0.0;
	float total_weight = 0.0;
	for (float x = -2.0; x <= 2.0; x += 1.0) {
		for (float y = -2.0; y <= 2.0; y += 1.0) {
			float weight = 1.0 / (1.0 + (x * x + y * y) * 0.5);
			alpha += texture(TEXTURE, target_uv + vec2(x * ps.x, y * ps.y)).a * weight;
			total_weight += weight;
		}
	}
	alpha /= total_weight;
	
	COLOR = vec4(0.0, 0.0, 0.0, alpha * shadow_opacity * sky_fade);
}
