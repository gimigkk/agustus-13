shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 0.0;

void fragment() {
    vec4 col = vec4(0.0);
    float total_weight = 0.0;
    
    // 7x7 Gaussian Kernel
    for (float x = -3.0; x <= 3.0; x++) {
        for (float y = -3.0; y <= 3.0; y++) {
            float r = (x * x + y * y);
            float weight = exp(-r / 6.0);
            col += texture(TEXTURE, UV + vec2(x, y) * TEXTURE_PIXEL_SIZE * blur_amount) * weight;
            total_weight += weight;
        }
    }
    
    COLOR = (col / total_weight) * vec4(1.0, 1.0, 1.0, COLOR.a);
}
