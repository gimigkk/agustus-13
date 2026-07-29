extends CanvasLayer

## Modal popup displaying individual letter textures or custom message dialogs.

@onready var letter_image: TextureRect = $Control/LetterContainer/LetterImage
@onready var fallback_label: Label = $Control/LetterContainer/FallbackLabel
@onready var control: Control = $Control
@onready var panel: Control = $Control/LetterContainer
@onready var dim_bg: ColorRect = $Control/DimBackground

var _tween: Tween

func _ready() -> void:
	control.hide()

## Displays the letter image or text content for a specific letter ID.
func show_letter(letter_id: int) -> void:
	LetterManager.mark_letter_as_read(letter_id)
	var data = LetterManager.get_letter_data(letter_id)
	var img_path = data.get("image", "")
	
	if img_path != "":
		var texture = load(img_path) as Texture2D
		if texture:
			letter_image.texture = texture
			letter_image.show()
			fallback_label.hide()
		else:
			letter_image.hide()
			fallback_label.text = data.get("text", LetterManager.get_letter_message(letter_id))
			fallback_label.show()
	else:
		letter_image.hide()
		fallback_label.text = data.get("text", LetterManager.get_letter_message(letter_id))
		fallback_label.show()
	
	_animate_in()

## Shows a custom title and text message inside the popup panel.
func display_message(_title: String, message: String) -> void:
	letter_image.hide()
	fallback_label.text = message
	fallback_label.show()
	_animate_in()

## Closes the active popup modal.
func hide_popup() -> void:
	if _tween: _tween.kill()
	control.hide()

func _animate_in() -> void:
	control.show()
	if _tween: _tween.kill()
	_tween = create_tween().set_parallel(true)
	
	var viewport_height = get_viewport().get_visible_rect().size.y
	# The default Y position of the centered panel (1280 / 2) - (800 / 2) = 240
	var target_y = (viewport_height / 2.0) - 400.0
	
	# Initial state
	panel.position.y = viewport_height + 50.0
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size / 2.0
	dim_bg.modulate.a = 0.0
	dim_bg.material.set_shader_parameter("blur_radius", 0.0)
	letter_image.material.set_shader_parameter("blur_amount", 25.0)
	
	# Tweening
	_tween.tween_property(panel, "position:y", target_y, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	
	_tween.tween_method(func(v: float): dim_bg.material.set_shader_parameter("blur_radius", v), 0.0, 12.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	_tween.tween_method(func(v: float): letter_image.material.set_shader_parameter("blur_amount", v), 25.0, 0.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	_tween.tween_property(dim_bg, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

func _input(event: InputEvent) -> void:
	if not control.visible:
		return
		
	if event.is_action_pressed("ui_cancel"):
		hide_popup()
		get_viewport().set_input_as_handled()
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local_pos = panel.get_local_mouse_position()
		var hitbox = Rect2(Vector2.ZERO, panel.size)
		
		# If the image is loaded, calculate the precise letterboxed rect so clicking the transparent margins counts as outside
		if letter_image.visible and letter_image.texture:
			var tex_size = letter_image.texture.get_size()
			var rect_size = letter_image.size
			var scale_factor = min(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
			var drawn_size = tex_size * scale_factor
			var drawn_pos = (rect_size - drawn_size) / 2.0
			hitbox = Rect2(drawn_pos, drawn_size)
			
		if not hitbox.has_point(local_pos):
			hide_popup()
			get_viewport().set_input_as_handled()
