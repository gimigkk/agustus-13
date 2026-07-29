extends RigidBody2D

signal letter_selected(letter_id: int)

@export var letter_id: int = 1

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_linear_damp: float = 0.0
var _drag_tween: Tween
var _shadow_offset: float = 3.0
var _initial_rotation: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var glow_sprite: Sprite2D = get_node_or_null("GlowSprite")
@onready var id_label: Label = $Label

var _pulse_time: float = 0.0
var _is_unread: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_original_linear_damp = linear_damp
	input_pickable = true
	shadow_sprite.top_level = true
	id_label.text = "#%d" % letter_id
	_pulse_time = randf_range(0.0, 6.28)
	
	_update_read_status()
	if LetterManager and LetterManager.has_signal("letter_read"):
		LetterManager.letter_read.connect(_on_letter_read)

func _update_read_status() -> void:
	if LetterManager:
		_is_unread = not LetterManager.is_letter_read(letter_id)
	else:
		_is_unread = false
	if glow_sprite:
		glow_sprite.visible = _is_unread

func _on_letter_read(p_letter_id: int) -> void:
	if p_letter_id == letter_id and _is_unread:
		_is_unread = false
		if glow_sprite:
			var tw = create_tween()
			tw.tween_property(glow_sprite, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_OUT)
			tw.tween_callback(func(): if is_instance_valid(glow_sprite): glow_sprite.hide())

func _start_drag() -> void:
	_dragging = true
	_drag_offset = global_position - get_global_mouse_position()
	freeze = true # Freeze physics while dragging
	letter_selected.emit(letter_id)
	get_viewport().set_input_as_handled()
	
	_initial_rotation = rotation
	
	if _drag_tween: _drag_tween.kill()
	_drag_tween = create_tween().set_parallel(true)
	_drag_tween.tween_property(self, "rotation", 0.0, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_drag_tween.tween_property(sprite, "scale", Vector2(0.55, 0.55), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_drag_tween.tween_property(shadow_sprite, "scale", Vector2(0.55 * 1.15, 0.55 * 1.15), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_drag_tween.tween_property(shadow_sprite, "modulate:a", 0.4, 0.15)
	_drag_tween.tween_property(self, "_shadow_offset", 15.0, 0.15)
	_drag_tween.tween_property(shadow_sprite.material, "shader_parameter/blur_amount", 2.5, 0.15)

func _stop_drag() -> void:
	if not _dragging: return
	_dragging = false
	freeze = false
	
	if _drag_tween: _drag_tween.kill()
	_drag_tween = create_tween().set_parallel(true)
	_drag_tween.tween_property(self, "rotation", _initial_rotation, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_drag_tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_drag_tween.tween_property(shadow_sprite, "scale", Vector2(0.5 * 1.15, 0.5 * 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_drag_tween.tween_property(shadow_sprite, "modulate:a", 0.6, 0.15)
	_drag_tween.tween_property(self, "_shadow_offset", 3.0, 0.15)
	_drag_tween.tween_property(shadow_sprite.material, "shader_parameter/blur_amount", 0.0, 0.15)

func _process(delta: float) -> void:
	if _dragging:
		global_position = get_global_mouse_position() + _drag_offset
		global_position.x = clampf(global_position.x, 80.0, 720.0 - 80.0)
		global_position.y = clampf(global_position.y, 80.0, 1280.0 - 80.0)
		
	shadow_sprite.global_position = global_position + Vector2(0, _shadow_offset)
	shadow_sprite.rotation = rotation
	
	if glow_sprite and _is_unread and glow_sprite.visible:
		_pulse_time += delta * 4.0
		var pulse := (sin(_pulse_time) + 1.0) * 0.5 # 0.0 to 1.0
		glow_sprite.modulate = Color(1.0, 0.88, 0.45, lerpf(0.35, 0.95, pulse))
		var base_scale_x: float = sprite.scale.x * 1.14
		var base_scale_y: float = sprite.scale.y * 1.20
		var pulse_x: float = pulse * 0.025
		var pulse_y: float = pulse * 0.030
		glow_sprite.scale = Vector2(base_scale_x + pulse_x, base_scale_y + pulse_y)

# We also need to stop dragging if the mouse button is released outside the collision shape
func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_stop_drag()
