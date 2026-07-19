@tool
extends StaticBody2D

## Centered StaticBody2D Platform with viewport gizmo sync
@export var size: Vector2 = Vector2(200, 30):
	set(value):
		size = value
		_update_platform()

@export var color: Color = Color(0.35, 0.4, 0.5, 1.0):
	set(value):
		color = value
		_update_platform()

@onready var visual: ColorRect = $Visual
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	_update_platform()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		# Sync visual automatically if CollisionShape2D gizmo is dragged in editor
		if collision and collision.shape is RectangleShape2D:
			var shape_size = collision.shape.size
			if shape_size != size and shape_size != Vector2.ZERO:
				size = shape_size

func _update_platform() -> void:
	if not is_inside_tree():
		return

	if collision:
		var rect_shape: RectangleShape2D
		if collision.shape is RectangleShape2D:
			rect_shape = collision.shape
		else:
			rect_shape = RectangleShape2D.new()
			collision.shape = rect_shape

		if rect_shape.size != size:
			rect_shape.size = size

	if visual:
		visual.position = -size / 2.0
		visual.size = size
		visual.color = color
