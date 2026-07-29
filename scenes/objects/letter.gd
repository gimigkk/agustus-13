@tool
extends Area2D

## Collectible Letter Entity.
## Dependencies:
## - Autoload: LetterManager.
## - Implicit Node Behavior: Inactive if node name contains digits (e.g. "Letter_05" auto-sets letter_id = 5).

@export var letter_id: int = 1:
	set(value):
		letter_id = max(1, value)
		_update_visual()

@export var letter_count: int = 1:
	set(value):
		letter_count = max(1, value)
		_update_visual()

var base_y: float = 0.0
var anim_time: float = 0.0
var is_collected: bool = false

var single_tex: Texture2D = preload("res://assets/objects/single_letter.png")
var stack_tex: Texture2D = preload("res://assets/objects/letter_stack.png")

@onready var visual: Sprite2D = $Visual

func _ready() -> void:
	base_y = position.y
	_auto_infer_id_from_name()
	_update_visual()
	
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		if LetterManager.is_bundle_collected(letter_id, letter_count):
			queue_free()

# Implicit Regex Rule: Extracts trailing digits from node instance name (e.g., "Letter_14" -> letter_id = 14)
# to avoid manual editor inspector entry for every scene copy.
func _auto_infer_id_from_name() -> void:
	var regex := RegEx.new()
	regex.compile("\\d+")
	var result := regex.search(name)
	if result:
		var parsed_id: int = result.get_string().to_int()
		if parsed_id > 0 and letter_id == 1:
			letter_id = parsed_id

func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		anim_time += delta
		position.y = base_y + sin(anim_time * 3.0) * 6.0

func _update_visual() -> void:
	if visual:
		if letter_count > 1:
			visual.texture = stack_tex
		else:
			visual.texture = single_tex

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
		
	if body is CharacterBody2D:
		if not body.is_physics_processing():
			return
		is_collected = true
		LetterManager.collect_letter_bundle(letter_id, letter_count, body.global_position, global_position)
		queue_free()
