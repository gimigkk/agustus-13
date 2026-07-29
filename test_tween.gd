extends SceneTree
func _init():
    var rect = ColorRect.new()
    var mat = ShaderMaterial.new()
    mat.shader = load("res://shaders/menu_blur.gdshader")
    rect.material = mat
    var tween = create_tween()
    tween.tween_property(mat, "shader_parameter/blur_radius", 25.0, 1.0)
    print("Tween valid: ", tween.is_valid())
    quit()
