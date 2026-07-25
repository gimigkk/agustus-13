extends RefCounted
class_name UIThemeHelper

## Helper utility for styling Godot GUI Buttons with a modern Fake 3D / Animated Button look
## Inspired by AnimatedButton.css

static func apply_fake_3d_style(
	button: Button,
	primary_color: Color = Color(0.12, 0.14, 0.18, 0.95),
	border_color: Color = Color(0.9, 0.95, 1.0, 0.9),
	hover_bg_color: Color = Color(0.97, 0.98, 1.0, 1.0),
	hover_text_color: Color = Color(0.06, 0.09, 0.16, 1.0),
	active_border_color: Color = Color(0.68, 1.0, 0.18, 1.0), # greenyellow
	corner_radius: int = 24
) -> void:
	if not is_instance_valid(button):
		return

	# 1. Normal Style (Sleek dark glass with 3D bottom bevel)
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = primary_color
	normal_style.set_corner_radius_all(corner_radius)
	normal_style.border_width_left = 3
	normal_style.border_width_top = 3
	normal_style.border_width_right = 3
	normal_style.border_width_bottom = 7
	normal_style.border_color = border_color
	normal_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	normal_style.shadow_size = 6
	normal_style.shadow_offset = Vector2(0, 4)
	normal_style.content_margin_left = 20
	normal_style.content_margin_right = 20
	normal_style.content_margin_top = 10
	normal_style.content_margin_bottom = 14

	# 2. Hover Style (Inverted high-contrast highlight state)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = hover_bg_color
	hover_style.set_corner_radius_all(corner_radius)
	hover_style.border_width_left = 3
	hover_style.border_width_top = 3
	hover_style.border_width_right = 3
	hover_style.border_width_bottom = 7
	hover_style.border_color = Color(1.0, 1.0, 1.0, 1.0)
	hover_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	hover_style.shadow_size = 10
	hover_style.shadow_offset = Vector2(0, 6)
	hover_style.content_margin_left = 20
	hover_style.content_margin_right = 20
	hover_style.content_margin_top = 10
	hover_style.content_margin_bottom = 14

	# 3. Pressed Style (3D button pressed flat down with active greenyellow ring)
	var pressed_style := StyleBoxFlat.new()
	pressed_style.bg_color = primary_color
	pressed_style.set_corner_radius_all(corner_radius)
	pressed_style.border_width_left = 3
	pressed_style.border_width_top = 3
	pressed_style.border_width_right = 3
	pressed_style.border_width_bottom = 3
	pressed_style.border_color = active_border_color
	pressed_style.shadow_color = Color(0.0, 0.0, 0.0, 0.2)
	pressed_style.shadow_size = 2
	pressed_style.shadow_offset = Vector2(0, 1)
	pressed_style.content_margin_left = 20
	pressed_style.content_margin_right = 20
	pressed_style.content_margin_top = 14
	pressed_style.content_margin_bottom = 10

	# 4. Focus / Disabled Style
	var focus_style := normal_style.duplicate() as StyleBoxFlat
	focus_style.border_color = active_border_color

	# Apply StyleBoxes
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", focus_style)

	# Apply Typography Colors
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", hover_text_color)
	button.add_theme_color_override("font_pressed_color", active_border_color)
	button.add_theme_color_override("font_focus_color", Color(1.0, 1.0, 1.0, 1.0))

	# Connect Press Micro-Scale Animations
	if not button.is_connected("button_down", Callable(UIThemeHelper, "_on_btn_down").bind(button)):
		button.button_down.connect(Callable(UIThemeHelper, "_on_btn_down").bind(button))
	if not button.is_connected("button_up", Callable(UIThemeHelper, "_on_btn_up").bind(button)):
		button.button_up.connect(Callable(UIThemeHelper, "_on_btn_up").bind(button))

static func _on_btn_down(button: Button) -> void:
	if is_instance_valid(button):
		button.pivot_offset = button.size / 2.0
		var tw := button.create_tween()
		tw.tween_property(button, "scale", Vector2(0.95, 0.95), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func _on_btn_up(button: Button) -> void:
	if is_instance_valid(button):
		button.pivot_offset = button.size / 2.0
		var tw := button.create_tween()
		tw.tween_property(button, "scale", Vector2(1.0, 1.0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
