shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 20.0) = 5.0;
uniform float shadow_opacity : hint_range(0.0, 1.0) = 0.50;
uniform float radial_outward : hint_range(0.0, 0.1) = 0.035; // Outward X displacement from center
uniform float vertical_offset : hint_range(0.0, 30.0) = 10.0; // Downward Y displacement (px)

void fragment() {
	// Radial shadow offset: X offset expands outwards from center (UV.x = 0.5)
	vec2 offset_uv = vec2(
		(UV.x - 0.5) * radial_outward,
		TEXTURE_PIXEL_SIZE.y * vertical_offset
	);
	
	vec2 target_uv = UV - offset_uv;
	vec2 ps = TEXTURE_PIXEL_SIZE * blur_amount;
	
	// 13-tap Gaussian Kernel Blur
	float alpha = 0.0;
	alpha += texture(TEXTURE, target_uv + vec2(-ps.x * 2.0, 0.0)).a * 0.05;
	alpha += texture(TEXTURE, target_uv + vec2(-ps.x, -ps.y)).a * 0.10;
	alpha += texture(TEXTURE, target_uv + vec2(0.0, -ps.y * 2.0)).a * 0.05;
	alpha += texture(TEXTURE, target_uv + vec2(0.0, -ps.y)).a * 0.15;
	alpha += texture(TEXTURE, target_uv + vec2(ps.x, -ps.y)).a * 0.10;
	alpha += texture(TEXTURE, target_uv + vec2(ps.x * 2.0, 0.0)).a * 0.05;
	
	alpha += texture(TEXTURE, target_uv).a * 0.25;
	
	alpha += texture(TEXTURE, target_uv + vec2(-ps.x, ps.y)).a * 0.10;
	alpha += texture(TEXTURE, target_uv + vec2(0.0, ps.y)).a * 0.15;
	alpha += texture(TEXTURE, target_uv + vec2(0.0, ps.y * 2.0)).a * 0.05;
	alpha += texture(TEXTURE, target_uv + vec2(ps.x, ps.y)).a * 0.10;
	
	COLOR = vec4(0.0, 0.0, 0.0, alpha * shadow_opacity);
}
