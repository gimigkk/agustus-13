extends Node2D

## Main Level Script managing Intro Cutscene & Global level state
const IntroCutsceneScript = preload("res://scripts/intro_cutscene.gd")

@export var auto_play_intro_on_editor_test: bool = true

func _ready() -> void:
	print("[TestLevel] _ready() called")
	var sm = get_node_or_null("/root/SaveManager")
	var should_intro: bool = auto_play_intro_on_editor_test
	
	if sm:
		print("[TestLevel] SaveManager found. force_intro=", sm.force_intro_on_launch, " has_save=", sm.current_save_data.get("has_save", false))
		if sm.force_intro_on_launch or not sm.current_save_data.get("has_save", false):
			should_intro = true
			sm.force_intro_on_launch = false
	else:
		print("[TestLevel] SaveManager NOT found!")
			
	print("[TestLevel] should_intro=", should_intro)
	if should_intro:
		print("[TestLevel] Calling play_intro_sequence deferred...")
		call_deferred("play_intro_sequence")
	else:
		print("[TestLevel] Skipping intro.")

func play_intro_sequence() -> void:
	print("[TestLevel] play_intro_sequence() called")
	var existing = get_node_or_null("IntroCutsceneManager")
	if is_instance_valid(existing):
		existing.queue_free()

	var intro = IntroCutsceneScript.new()
	intro.name = "IntroCutsceneManager"
	add_child(intro)
	intro.intro_completed.connect(func():
		if is_instance_valid(intro):
			intro.queue_free()
	)
	intro.play_intro(self)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		print("[TestLevel] F2 pressed -> triggering intro")
		play_intro_sequence()
