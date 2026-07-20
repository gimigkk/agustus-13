extends Node2D

## Fall Target Marker for Intro Cutscene (defines bottom landing spot in editor)
@onready var visual: ColorRect = $Visual
@onready var label: Label = $Visual/Label

func _ready() -> void:
	# Hide visual marker during runtime gameplay
	if not Engine.is_editor_hint():
		if visual:
			visual.hide()
