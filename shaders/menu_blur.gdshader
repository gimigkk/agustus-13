shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius : hint_range(0.0, 10.0) = 4.0;
uniform vec4 dim_color : source_color = vec4(0.0, 0.0, 0.0, 0.2);

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Dynamically calculate hardware Mipmap LOD level based on blur radius.
	// This gives us massive CSS-style blur radii without tanking performance.
	float lod = clamp(blur_radius / 2.0, 0.0, 4.0);
	
	// Scale sample spacing to match the LOD resolution exactly.
	// This guarantees ZERO skipped pixels on the mipmap, completely eliminating "blockiness".
	vec2 size = SCREEN_PIXEL_SIZE * pow(2.0, lod);
	
	vec4 col = vec4(0.0);
	float total_weight = 0.0;
	
	// Dense 7x7 Gaussian Kernel applied to the Mipmap
	for (float x = -3.0; x <= 3.0; x++) {
		for (float y = -3.0; y <= 3.0; y++) {
			float r = (x * x + y * y);
			float weight = exp(-r / 6.0); // Wide, soft Gaussian bell curve
			
			col += textureLod(screen_texture, uv + vec2(x, y) * size, lod) * weight;
			total_weight += weight;
		}
	}
	
	col /= total_weight;
	
	COLOR = vec4(mix(col.rgb, dim_color.rgb, dim_color.a), 1.0);
}
