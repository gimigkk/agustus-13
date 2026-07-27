@tool
extends Control
class_name UiverseButton

## Custom 3D tactile push button component with rest/hover/pressed elevation effects.

## Button display label.
@export var text: String = "":
	set(val):
		text = val
		if top_button:
			top_button.text = val

## Icon texture displayed on the button surface.
@export var icon_texture: Texture2D:
	set(val):
		icon_texture = val
		if top_button:
			top_button.icon = val
			if val:
				top_button.expand_icon = true
				top_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

## Label font size override.
@export var font_size: int = 24:
	set(val):
		font_size = val
		if top_button:
			top_button.add_theme_font_size_override("font_size", val)

## Disabled state toggle.
@export var disabled: bool = false:
	set(val):
		disabled = val
		if top_button:
			top_button.disabled = val
		modulate.a = 0.4 if val else 1.0


@export_group("3D Elevation Offsets")

## Y offset of top button surface when idle.
@export var offset_rest: float = -12.0:
	set(val):
		offset_rest = val
		if top_button and not is_externally_pressed:
			top_button.position.y = val

## Y offset of top button surface when hovered.
@export var offset_hover: float = -16.0

## Y offset of top button surface when pressed down.
@export var offset_pressed: float = 0.0

## Emitted when button press begins.
signal button_down

## Emitted when button press is released.
signal button_up

## Emitted when button interaction completes.
signal pressed

var base_panel: Panel
var top_button: Button
var tween: Tween
var is_externally_pressed: bool = false
var charge_shake_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	_setup_nodes()

func _setup_nodes() -> void:
	focus_mode = Control.FOCUS_NONE
	
	base_panel = get_node_or_null("BasePanel") as Panel
	top_button = get_node_or_null("TopButton") as Button

	# Create BasePanel if it doesn't exist
	if not base_panel:
		base_panel = Panel.new()
		base_panel.name = "BasePanel"
		base_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		base_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(base_panel)

	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color("#000000")
	base_style.set_corner_radius_all(10)
	base_panel.add_theme_stylebox_override("panel", base_style)
	
	# Create TopButton if it doesn't exist
	if not top_button:
		top_button = Button.new()
		top_button.name = "TopButton"
		top_button.set_anchors_preset(Control.PRESET_FULL_RECT)
		top_button.position = Vector2(0, offset_rest)
		top_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_child(top_button)

	top_button.focus_mode = Control.FOCUS_NONE
	top_button.disabled = disabled
	modulate.a = 0.4 if disabled else 1.0

	if not is_externally_pressed:
		top_button.position.y = offset_rest
	top_button.text = text
	if icon_texture:
		top_button.icon = icon_texture
		top_button.expand_icon = true
		top_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

	top_button.add_theme_font_size_override("font_size", font_size)
	
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color("#e8e8e8")
	top_style.border_color = Color("#000000")
	top_style.set_border_width_all(2)
	top_style.set_corner_radius_all(10)
	
	var top_style_pressed := top_style.duplicate() as StyleBoxFlat
	top_style_pressed.bg_color = Color("#d8d8d8")
	
	top_button.add_theme_stylebox_override("normal", top_style)
	top_button.add_theme_stylebox_override("hover", top_style)
	top_button.add_theme_stylebox_override("pressed", top_style_pressed)
	top_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	top_button.add_theme_color_override("font_color", Color("#000000"))
	top_button.add_theme_color_override("font_hover_color", Color("#000000"))
	top_button.add_theme_color_override("font_pressed_color", Color("#000000"))
	top_button.add_theme_color_override("font_focus_color", Color("#000000"))

	top_button.add_theme_color_override("icon_normal_color", Color("#000000"))
	top_button.add_theme_color_override("icon_hover_color", Color("#000000"))
	top_button.add_theme_color_override("icon_pressed_color", Color("#000000"))
	top_button.add_theme_color_override("icon_focus_color", Color("#000000"))
	
	if not Engine.is_editor_hint():
		top_button.mouse_entered.connect(_on_mouse_entered)
		top_button.mouse_exited.connect(_on_mouse_exited)
		top_button.button_down.connect(_on_button_down)
		top_button.button_up.connect(_on_button_up)
		top_button.pressed.connect(_on_pressed_internal)

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
	if is_externally_pressed:
		_animate_to_y(offset_pressed, 0.04)
	else:
		if top_button and top_button.is_hovered():
			_animate_to_y(offset_hover, 0.08)
		else:
			_animate_to_y(offset_rest, 0.08)

func _on_pressed_internal() -> void:
	pressed.emit()

func _animate_to_y(target_y: float, duration: float = 0.08) -> void:
	if not top_button or not is_inside_tree():
		return
	if tween:
		tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(top_button, "position:y", target_y, duration)

func _on_mouse_entered() -> void:
	if top_button and not top_button.is_pressed() and not is_externally_pressed:
		_animate_to_y(offset_hover, 0.08)

func _on_mouse_exited() -> void:
	if top_button and not top_button.is_pressed() and not is_externally_pressed:
		_animate_to_y(offset_rest, 0.08)

func _on_button_down() -> void:
	button_down.emit()
	if not is_externally_pressed:
		_animate_to_y(offset_pressed, 0.04)

func _on_button_up() -> void:
	button_up.emit()
	if not is_externally_pressed:
		if top_button and top_button.is_hovered():
			_animate_to_y(offset_hover, 0.08)
		else:
			_animate_to_y(offset_rest, 0.08)
