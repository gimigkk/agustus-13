@tool
extends Control
class_name UiverseButton

## Custom 3D tactile push button component inspired by Josh W Comeau's CSS buttons.

@export var text: String = "":
	set(val):
		text = val
		if top_button:
			top_button.text = val

@export var icon_texture: Texture2D:
	set(val):
		icon_texture = val
		if top_button:
			top_button.icon = val
			if val:
				top_button.expand_icon = true
				top_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

@export var font_size: int = 24:
	set(val):
		font_size = val
		if top_button:
			top_button.add_theme_font_size_override("font_size", val)

@export var disabled: bool = false:
	set(val):
		disabled = val
		if top_button:
			top_button.disabled = val
		modulate.a = 0.4 if val else 1.0

@export_group("3D Elevation Offsets")
@export var offset_rest: float = -10.0:
	set(val):
		offset_rest = val
		if current_state == ButtonState.IDLE:
			_apply_state(ButtonState.IDLE, 0.0)

@export var offset_hover: float = -15.0
@export var offset_pressed: float = 0.0

signal button_down
signal button_up
signal pressed

var shadow_panel: Panel
var edge_panel: Panel
var top_button: Button

var tween: Tween
var is_externally_pressed: bool = false
var charge_shake_offset: Vector2 = Vector2.ZERO

enum ButtonState { IDLE, HOVER, PRESSED }
var current_state: ButtonState = ButtonState.IDLE

func _ready() -> void:
	_setup_nodes()
	_update_styles()

func _setup_nodes() -> void:
	focus_mode = Control.FOCUS_NONE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(0, 70)
	
	var old_base = get_node_or_null("BasePanel")
	if old_base:
		old_base.queue_free()
		remove_child(old_base)
		
	var old_edge_mask = get_node_or_null("EdgeMask")
	if old_edge_mask:
		old_edge_mask.queue_free()
		remove_child(old_edge_mask)
		
	shadow_panel = get_node_or_null("ShadowPanel") as Panel
	edge_panel = get_node_or_null("EdgePanel") as Panel
	top_button = get_node_or_null("TopButton") as Button
	
	if not shadow_panel:
		shadow_panel = Panel.new()
		shadow_panel.name = "ShadowPanel"
		shadow_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shadow_panel)

	if not edge_panel:
		edge_panel = Panel.new()
		edge_panel.name = "EdgePanel"
		edge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(edge_panel)

	if not top_button:
		top_button = Button.new()
		top_button.name = "TopButton"
		top_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		top_button.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(top_button)
	else:
		top_button.mouse_filter = Control.MOUSE_FILTER_PASS

	# EdgePanel & ShadowPanel sit within the base bounding box (y = 0 to y = H)
	edge_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	edge_panel.offset_left = 0
	edge_panel.offset_top = 0
	edge_panel.offset_right = 0
	edge_panel.offset_bottom = 0
	
	shadow_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow_panel.offset_left = 0
	shadow_panel.offset_top = 0
	shadow_panel.offset_right = 0
	shadow_panel.offset_bottom = 2

	# TopButton elevates above the base box (y = offset_rest to y = H + offset_rest)
	top_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	top_button.offset_left = 0
	top_button.offset_top = offset_rest
	top_button.offset_right = 0
	top_button.offset_bottom = offset_rest

	top_button.focus_mode = Control.FOCUS_NONE
	top_button.disabled = disabled
	modulate.a = 0.4 if disabled else 1.0

	top_button.text = text
	if icon_texture:
		top_button.icon = icon_texture
		top_button.expand_icon = true
		top_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

	top_button.add_theme_font_size_override("font_size", font_size)
	
	if not is_externally_pressed:
		_apply_state(ButtonState.IDLE, 0.0)
	
	if not Engine.is_editor_hint():
		if top_button.mouse_entered.is_connected(_on_mouse_entered):
			top_button.mouse_entered.disconnect(_on_mouse_entered)
			top_button.mouse_exited.disconnect(_on_mouse_exited)
			top_button.button_down.disconnect(_on_button_down)
			top_button.button_up.disconnect(_on_button_up)
			top_button.pressed.disconnect(_on_pressed_internal)

		top_button.mouse_entered.connect(_on_mouse_entered)
		top_button.mouse_exited.connect(_on_mouse_exited)
		top_button.button_down.connect(_on_button_down)
		top_button.button_up.connect(_on_button_up)
		top_button.pressed.connect(_on_pressed_internal)

const GENTIUM_BOLD = preload("res://assets/fonts/GentiumBookPlus-Bold.ttf")

func _update_styles() -> void:
	if not edge_panel or not shadow_panel or not top_button:
		return

	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0, 0, 0, 0.25)
	shadow_style.set_corner_radius_all(8)
	shadow_panel.add_theme_stylebox_override("panel", shadow_style)
		
	var edge_style := StyleBoxFlat.new()
	edge_style.bg_color = Color("#cfcfcf")
	edge_style.set_corner_radius_all(8)
	edge_panel.add_theme_stylebox_override("panel", edge_style)
	
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color.WHITE
	top_style.set_corner_radius_all(8)
	top_style.content_margin_top = 4
	top_style.content_margin_bottom = 4
	
	top_button.add_theme_stylebox_override("normal", top_style)
	top_button.add_theme_stylebox_override("hover", top_style)
	top_button.add_theme_stylebox_override("pressed", top_style)
	top_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	var font_color = Color("#222222")
	top_button.add_theme_color_override("font_color", font_color)
	top_button.add_theme_color_override("font_hover_color", font_color)
	top_button.add_theme_color_override("font_pressed_color", font_color)
	top_button.add_theme_color_override("font_focus_color", font_color)

	top_button.remove_theme_constant_override("outline_size")
	top_button.remove_theme_color_override("font_outline_color")

	if GENTIUM_BOLD:
		top_button.add_theme_font_override("font", GENTIUM_BOLD)
	else:
		var sys_font := SystemFont.new()
		sys_font.font_weight = 700
		top_button.add_theme_font_override("font", sys_font)

	top_button.add_theme_color_override("icon_normal_color", font_color)
	top_button.add_theme_color_override("icon_hover_color", font_color)
	top_button.add_theme_color_override("icon_pressed_color", font_color)
	top_button.add_theme_color_override("icon_focus_color", font_color)

func set_charge_shake(ratio: float) -> void:
	if ratio > 0.0:
		var shake_mag := ratio * 6.0
		charge_shake_offset = Vector2(randf_range(-shake_mag, shake_mag), randf_range(-shake_mag, shake_mag))
	else:
		charge_shake_offset = Vector2.ZERO
	
	if top_button:
		top_button.position.x = charge_shake_offset.x
		if ratio > 0.0:
			pivot_offset = size / 2.0
			rotation_degrees = charge_shake_offset.x * 0.8
		else:
			rotation_degrees = 0.0

func set_external_pressed(p_pressed: bool) -> void:
	if is_externally_pressed == p_pressed:
		return
	is_externally_pressed = p_pressed
	_update_state()

func _update_state() -> void:
	if not is_inside_tree():
		return
	if is_externally_pressed or top_button.is_pressed():
		_apply_state(ButtonState.PRESSED)
	elif top_button.is_hovered():
		_apply_state(ButtonState.HOVER)
	else:
		_apply_state(ButtonState.IDLE)

func _apply_state(state: ButtonState, override_duration: float = -1.0) -> void:
	current_state = state
	
	var target_y := offset_rest
	var target_shadow_bottom := 2.0
	var duration := 0.2
	var trans := Tween.TRANS_BACK
	
	match state:
		ButtonState.IDLE:
			target_y = offset_rest
			target_shadow_bottom = 2.0
			duration = 0.2
			trans = Tween.TRANS_BACK
		ButtonState.HOVER:
			target_y = offset_hover
			target_shadow_bottom = 4.0
			duration = 0.15
			trans = Tween.TRANS_BACK
		ButtonState.PRESSED:
			target_y = offset_pressed
			target_shadow_bottom = 0.0
			duration = 0.05
			trans = Tween.TRANS_QUAD
	
	if override_duration >= 0.0:
		duration = override_duration
		
	_animate_to(target_y, target_shadow_bottom, duration, trans)

func _animate_to(target_y: float, target_shadow_bottom: float, duration: float, trans: int) -> void:
	if not top_button or not shadow_panel or not is_inside_tree():
		return
		
	if tween:
		tween.kill()
		
	var target_modulate := Color.WHITE
	if current_state == ButtonState.HOVER:
		target_modulate = Color(1.1, 1.1, 1.1)
	elif current_state == ButtonState.PRESSED:
		target_modulate = Color(0.85, 0.85, 0.85)
		
	target_modulate.a = 0.4 if disabled else 1.0

	if duration == 0.0:
		top_button.offset_top = target_y
		top_button.offset_bottom = target_y
		shadow_panel.offset_bottom = target_shadow_bottom
		modulate = target_modulate
		return
		
	tween = create_tween().set_parallel(true).set_trans(trans).set_ease(Tween.EASE_OUT)
	tween.tween_property(top_button, "offset_top", target_y, duration)
	tween.tween_property(top_button, "offset_bottom", target_y, duration)
	tween.tween_property(shadow_panel, "offset_bottom", target_shadow_bottom, duration)
	tween.tween_property(self, "modulate", target_modulate, duration)

func _on_pressed_internal() -> void:
	pressed.emit()

func _on_mouse_entered() -> void:
	_update_state()

func _on_mouse_exited() -> void:
	_update_state()

func _on_button_down() -> void:
	button_down.emit()
	_update_state()

func _on_button_up() -> void:
	button_up.emit()
	_update_state()
