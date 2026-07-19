@tool
extends Area2D

## Collectible Letter node with floating animation and collection handling
@export var letter_id: int = 1:
	set(value):
		letter_id = value
		_update_label()

var base_y: float = 0.0
var anim_time: float = 0.0

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Visual/Label

func _ready() -> void:
	base_y = position.y
	_update_label()
	
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		# Hide if already collected in this save
		if LetterManager and LetterManager.is_letter_collected(letter_id):
			queue_free()

func _process(delta: float) -> void:
	# Floating bobbing animation
	anim_time += delta
	position.y = base_y + sin(anim_time * 3.0) * 6.0

func _update_label() -> void:
	if label:
		label.text = str(letter_id)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if LetterManager:
			LetterManager.collect_letter(letter_id, body.global_position)
		queue_free()
