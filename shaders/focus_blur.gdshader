shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 0.0;

void fragment() {
	if (blur_amount <= 0.05) {
		COLOR = texture(TEXTURE, UV);
	} else {
		vec4 col = vec4(0.0);
		float total_weight = 0.0;
		vec2 size = TEXTURE_PIXEL_SIZE * blur_amount;
		
		for (float x = -1.0; x <= 1.0; x += 1.0) {
			for (float y = -1.0; y <= 1.0; y += 1.0) {
				float weight = (x == 0.0 && y == 0.0) ? 4.0 : ((x == 0.0 || y == 0.0) ? 2.0 : 1.0);
				col += texture(TEXTURE, UV + vec2(x, y) * size) * weight;
				total_weight += weight;
			}
		}
		
		COLOR = (col / total_weight) * vec4(1.0, 1.0, 1.0, COLOR.a);
	}
}
