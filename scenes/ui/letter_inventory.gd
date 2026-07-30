extends CanvasLayer

## Letter Inventory modal displaying a physics crate with collected letters.

const PHYSICS_LETTER_SCENE = preload("res://scenes/ui/physics_letter.tscn")

@onready var control: Control = $Control
@onready var title_label: Label = $Control/CenterContainer/VBoxContainer/DetailsPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var author_label: Label = $Control/CenterContainer/VBoxContainer/DetailsPanel/MarginContainer/VBoxContainer/AuthorLabel
@onready var read_button: Control = $Control/CenterContainer/VBoxContainer/ButtonContainer/ReadBtn
@onready var close_btn: Control = $Control/CenterContainer/VBoxContainer/ButtonContainer/CloseBtn
@onready var letters_container: Node2D = $Control/CenterContainer/VBoxContainer/CratePhysicsContainer/PhysicsWorld/LettersContainer
@onready var counter_label: Label = $Control/CenterContainer/VBoxContainer/CounterLabel
@onready var details_panel: PanelContainer = $Control/CenterContainer/VBoxContainer/DetailsPanel

var _showing_global: bool = false
var _selected_letter_id: int = -1

func _ready() -> void:
	control.hide()
	control.process_mode = Node.PROCESS_MODE_DISABLED
	if close_btn.has_signal("pressed"):
		close_btn.pressed.connect(hide_inventory)
	if read_button.has_signal("pressed"):
		read_button.pressed.connect(_on_read_pressed)

## Opens the inventory overlay and pauses gameplay.
func open_inventory(show_global: bool = false) -> void:
	_showing_global = show_global
	_populate_crate()
	
	# Validate or pick a new selection
	var is_valid = false
	if _selected_letter_id != -1:
		is_valid = LetterManager.is_global_letter_collected(_selected_letter_id) if _showing_global else LetterManager.is_letter_collected(_selected_letter_id)
		
	if not is_valid:
		_selected_letter_id = -1
		# Pick highest collected
		for i in range(21, 0, -1):
			var collected = LetterManager.is_global_letter_collected(i) if _showing_global else LetterManager.is_letter_collected(i)
			if collected:
				_selected_letter_id = i
				break
				
	if _selected_letter_id != -1:
		_on_letter_selected(_selected_letter_id)
		
	var count: int = LetterManager.global_letter_ids.size() if _showing_global else LetterManager.collected_letter_ids.size()
	counter_label.text = "%d / %d Letters" % [count, LetterManager.TOTAL_LETTERS]
	
	if count == 0:
		details_panel.hide()
	else:
		details_panel.show()
		
	_set_gameplay_ui_visible(false)

	control.show()
	control.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

## Closes the inventory overlay and unpauses gameplay.
func hide_inventory() -> void:
	control.hide()
	control.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Only restore gameplay UI if MainMenu is not currently open
	var current = get_tree().current_scene if get_tree() else null
	var main_menu = current.get_node_or_null("MainMenu") if current else null
	if not is_instance_valid(main_menu):
		_set_gameplay_ui_visible(true)
		
	get_tree().paused = false

func _set_gameplay_ui_visible(p_visible: bool) -> void:
	var current = get_tree().current_scene if get_tree() else null
	if not current:
		return
	var hud = current.get_node_or_null("HUD")
	if hud:
		if hud.has_method("set_top_bar_visible"):
			hud.set_top_bar_visible(p_visible)
		elif hud.has_node("Control"):
			hud.get_node("Control").visible = p_visible
	var touch = current.get_node_or_null("TouchControls")
	if touch:
		touch.visible = p_visible

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if control.visible:
			hide_inventory()

## Clears and rebuilds letter rigidbodies inside the crate.
func _populate_crate() -> void:
	for child in letters_container.get_children():
		child.queue_free()
	
	# Spawn collected letters
	for i in range(1, 22):
		var is_collected = LetterManager.is_global_letter_collected(i) if _showing_global else LetterManager.is_letter_collected(i)
		if is_collected:
			var letter_inst = PHYSICS_LETTER_SCENE.instantiate()
			letter_inst.letter_id = i
			
			# Add some random initial position/rotation inside the crate bounds
			var rand_x = randf_range(-150, 150)
			var rand_y = randf_range(-200, 100)
			letter_inst.position = Vector2(rand_x, rand_y)
			letter_inst.rotation = randf_range(-PI, PI)
			
			letters_container.add_child(letter_inst)
			letter_inst.letter_selected.connect(_on_letter_selected)

func _on_letter_selected(letter_id: int) -> void:
	_selected_letter_id = letter_id
	var data = LetterManager.get_letter_data(letter_id)
	var letter_title: String = data.get("title", "")
	if letter_title != "":
		title_label.text = letter_title
	else:
		title_label.text = "Letter #%d" % letter_id
	author_label.text = "letter by " + data.get("author", "Unknown")
	read_button.disabled = false
	
	for child in letters_container.get_children():
		if child.get("letter_id") == letter_id:
			letters_container.move_child(child, -1)
			break

## Opens full letter popup view for the currently selected letter ID.
func _on_read_pressed() -> void:
	if _selected_letter_id == -1:
		return
		
	var popup = get_node_or_null("../LetterPopup")
	if not popup and get_tree().current_scene:
		popup = get_tree().current_scene.get_node_or_null("HUD/LetterPopup")
	if popup:
		popup.show_letter(_selected_letter_id)

func _input(event: InputEvent) -> void:
	if not control.visible: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var space = letters_container.get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.canvas_instance_id = get_instance_id()
		query.position = letters_container.get_canvas_transform().affine_inverse() * event.position
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var results = space.intersect_point(query)
		if results.size() > 0:
			# Filter to only include PhysicsLetter nodes
			var letters = []
			for res in results:
				if res.collider.has_method("_start_drag"):
					letters.append(res.collider)
			
			if letters.size() > 0:
				# Sort by sibling index (highest is visually on top)
				letters.sort_custom(func(a, b): return a.get_index() > b.get_index())
				
				# Start dragging the top-most letter
				letters[0]._start_drag()
				get_viewport().set_input_as_handled()
