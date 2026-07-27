shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 3.5;
uniform float shadow_opacity : hint_range(0.0, 1.0) = 0.40;

void fragment() {
	vec2 ps = TEXTURE_PIXEL_SIZE * blur_amount;
	
	// 9-sample 2D Gaussian Kernel Blur
	float alpha = 0.0;
	alpha += texture(TEXTURE, UV + vec2(-ps.x, -ps.y)).a * 0.0625;
	alpha += texture(TEXTURE, UV + vec2( 0.0,  -ps.y)).a * 0.1250;
	alpha += texture(TEXTURE, UV + vec2( ps.x, -ps.y)).a * 0.0625;
	
	alpha += texture(TEXTURE, UV + vec2(-ps.x,  0.0)).a  * 0.1250;
	alpha += texture(TEXTURE, UV + vec2( 0.0,   0.0)).a  * 0.2500;
	alpha += texture(TEXTURE, UV + vec2( ps.x,  0.0)).a  * 0.1250;
	
	alpha += texture(TEXTURE, UV + vec2(-ps.x,  ps.y)).a * 0.0625;
	alpha += texture(TEXTURE, UV + vec2( 0.0,   ps.y)).a * 0.1250;
	alpha += texture(TEXTURE, UV + vec2( ps.x,  ps.y)).a * 0.0625;
	
	COLOR = vec4(0.0, 0.0, 0.0, alpha * shadow_opacity);
}
