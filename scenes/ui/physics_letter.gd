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
@onready var id_label: Label = $Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_original_linear_damp = linear_damp
	input_pickable = true
	shadow_sprite.top_level = true
	id_label.text = "#%d" % letter_id

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

# We also need to stop dragging if the mouse button is released outside the collision shape
func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_stop_drag()
