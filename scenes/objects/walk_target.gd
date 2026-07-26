extends Node2D

## Walk Target Marker for Outro Cutscene (defines final walk destination in editor)
@onready var visual: ColorRect = $Visual
@onready var label: Label = $Visual/Label

func _ready() -> void:
	# Hide visual marker during runtime gameplay
	if not Engine.is_editor_hint():
		if visual:
			visual.hide()
