shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 20.0) = 5.0;
uniform float shadow_opacity : hint_range(0.0, 1.0) = 0.55;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE * blur_amount;
	
	float alpha = 0.0;
	alpha += texture(TEXTURE, UV + vec2(-ps.x * 2.0, 0.0)).a * 0.05;
	alpha += texture(TEXTURE, UV + vec2(-ps.x, -ps.y)).a * 0.10;
	alpha += texture(TEXTURE, UV + vec2(0.0, -ps.y * 2.0)).a * 0.05;
	alpha += texture(TEXTURE, UV + vec2(0.0, -ps.y)).a * 0.15;
	alpha += texture(TEXTURE, UV + vec2(ps.x, -ps.y)).a * 0.10;
	alpha += texture(TEXTURE, UV + vec2(ps.x * 2.0, 0.0)).a * 0.05;
	
	alpha += texture(TEXTURE, UV).a * 0.25;
	
	alpha += texture(TEXTURE, UV + vec2(-ps.x, ps.y)).a * 0.10;
	alpha += texture(TEXTURE, UV + vec2(0.0, ps.y)).a * 0.15;
	alpha += texture(TEXTURE, UV + vec2(0.0, ps.y * 2.0)).a * 0.05;
	alpha += texture(TEXTURE, UV + vec2(ps.x, ps.y)).a * 0.10;
	
	COLOR = vec4(0.0, 0.0, 0.0, alpha * shadow_opacity);
}
