extends CanvasLayer

## In-game HUD overlay for letter count tracking, developer hotkeys, and inventory modal access.

@onready var control: Control = $Control
@onready var letter_counter_btn: Button = $Control/TopBar/HBoxContainer/LetterCounterBtn
@onready var counter_label: Label = $Control/TopBar/HBoxContainer/LetterCounterBtn/Content/CounterLabel
@onready var menu_btn: Control = $Control/TopBar/HBoxContainer/MenuBtn
@onready var letter_inventory: CanvasLayer = $LetterInventory

var current_displayed_count: int = 0

func _ready() -> void:
	control.show()
	
	var count: int = LetterManager.get_collected_count()
	current_displayed_count = count
	update_counter(count)
	
	# Listen to global LetterManager signal to trigger flying paper counter animation
	LetterManager.letter_collected.connect(_on_letter_collected)
	letter_counter_btn.pressed.connect(_on_counter_pressed)
	if menu_btn.has_signal("pressed"):
		menu_btn.pressed.connect(_on_menu_pressed)

# Developer hotkeys for instant summit completion (F1) and intro cutscene test (F2)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_on_debug_end_pressed()
		elif event.keycode == KEY_F2:
			_on_debug_intro_pressed()

## Updates the letter count text on the HUD button.
func update_counter(count: int) -> void:
	var total_available: int = LetterManager.TOTAL_LETTERS
	var safe_count: int = clampi(count, 0, total_available)
	current_displayed_count = safe_count
	var text_str := "%d / %d Letters" % [safe_count, total_available]
	if is_instance_valid(counter_label):
		counter_label.text = text_str
	letter_counter_btn.text = ""



## Displays a prompt informing the player how many letters remain for the full ending and shakes counter.
func show_incomplete_prompt(collected: int, required: int) -> void:
	shake_counter()
	var popup_scene = load("res://scenes/ui/letter_popup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		popup.display_message("Summit Reached!", "You made it to the top! But you still need to collect all %d letters to unlock the birthday surprise! (%d/%d collected)" % [required, collected, required])

## Shakes the letter counter button as a visual indicator for incomplete letter requirement.
func shake_counter() -> void:
	if not letter_counter_btn:
		return
	var target_node: Control = letter_counter_btn.get_node_or_null("Content") as Control
	if not target_node:
		target_node = letter_counter_btn
		
	target_node.pivot_offset = Vector2(40.0, target_node.size.y * 0.5)
	var orig_color := target_node.modulate
	
	# Flash red tint indicator
	var flash_tween := create_tween()
	flash_tween.tween_property(target_node, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.06)
	flash_tween.tween_property(target_node, "modulate", orig_color, 0.40)
	
	# Vigorously shake rotation & scale
	var shake_tween := create_tween()
	var num_shakes := 8
	for i in range(num_shakes):
		var rot := 14.0 if (i % 2 == 0) else -14.0
		var sc := Vector2(1.22, 1.22) if (i % 2 == 0) else Vector2(0.85, 0.85)
		shake_tween.tween_property(target_node, "rotation_degrees", rot, 0.04).set_trans(Tween.TRANS_QUAD)
		shake_tween.parallel().tween_property(target_node, "scale", sc, 0.04)
	
	shake_tween.chain().tween_property(target_node, "rotation_degrees", 0.0, 0.08).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	shake_tween.parallel().tween_property(target_node, "scale", Vector2(1.0, 1.0), 0.08)

## Callback when a letter is collected in-game.
func _on_letter_collected(_id: int, _msg: String, total: int, collect_pos: Vector2 = Vector2.ZERO) -> void:
	_animate_flying_papers(collect_pos, total)

func _animate_flying_papers(collect_world_pos: Vector2, new_total: int) -> void:
	if not letter_counter_btn or not control:
		update_counter(new_total)
		return

	# Target position: HUD Counter button center-left
	var target_rect := letter_counter_btn.get_global_rect()
	var target_pos := target_rect.position + Vector2(36.0, target_rect.size.y * 0.5)

	# Start position: Canvas screen space of collected item
	var start_pos: Vector2
	if collect_world_pos != Vector2.ZERO and get_viewport():
		start_pos = get_viewport().get_canvas_transform() * collect_world_pos
	elif get_viewport():
		start_pos = get_viewport().get_visible_rect().size * 0.5
	else:
		start_pos = Vector2(200.0, 300.0)

	var start_count: int = current_displayed_count
	var count_diff: int = max(1, new_total - start_count)
	var num_flyers: int = mini(3, count_diff) if count_diff > 1 else 1

	for i in range(num_flyers):
		var paper := _create_paper_node()
		control.add_child(paper)

		var delay := float(i) * 0.08

		# 1. Subtle, clean fan-out burst
		var base_angle_step := (PI * 0.35) / maxf(1.0, float(num_flyers - 1)) if num_flyers > 1 else 0.0
		var burst_angle := (-PI * 0.67) + float(i) * base_angle_step + randf_range(-0.08, 0.08)
		var burst_dist := randf_range(20.0, 35.0)
		var burst_pos := start_pos + Vector2(cos(burst_angle), sin(burst_angle)) * burst_dist

		# 2. Gentle 3-lane curve separation towards top-left counter
		var x_curve_bias: float
		if num_flyers == 1:
			x_curve_bias = randf_range(-15.0, 15.0)
		else:
			x_curve_bias = lerpf(-35.0, 35.0, float(i) / float(num_flyers - 1)) + randf_range(-10.0, 10.0)
			
		var y_arc_height := randf_range(60.0, 90.0)
		
		var mid_pos := (burst_pos + target_pos) * 0.5
		var control_pt := Vector2(
			mid_pos.x + x_curve_bias,
			minf(burst_pos.y, target_pos.y) - y_arc_height
		)

		paper.global_position = start_pos - paper.pivot_offset
		paper.scale = Vector2(0.2, 0.2)
		paper.modulate.a = 0.0

		# 3. Gentle paper drift rotation (45 to 110 degrees)
		var spin_dir := 1.0 if (i % 2 == 0) else -1.0
		var start_rot := randf_range(-15.0, 15.0)
		var total_tumble := randf_range(45.0, 110.0) * spin_dir
		var target_rot := start_rot + total_tumble

		var main_tween := create_tween()
		main_tween.tween_interval(delay)

		# Stage 1: Soft pop & burst (0.14s)
		main_tween.tween_property(paper, "global_position", burst_pos - paper.pivot_offset, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		main_tween.parallel().tween_property(paper, "scale", Vector2(0.75, 0.75), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		main_tween.parallel().tween_property(paper, "modulate:a", 1.0, 0.10)
		main_tween.parallel().tween_property(paper, "rotation_degrees", start_rot, 0.14)

		# Stage 2: Smooth Glide along gentle arc to HUD (0.45s)
		var fly_dur := 0.45
		var p_start := burst_pos
		var p_ctrl := control_pt
		var p_end := target_pos
		var p_node := paper
		var p_pivot := paper.pivot_offset

		main_tween.chain().tween_method(
			func(t: float):
				if is_instance_valid(p_node):
					var q_pos := (1.0 - t) * (1.0 - t) * p_start + 2.0 * (1.0 - t) * t * p_ctrl + t * t * p_end
					p_node.global_position = q_pos - p_pivot,
			0.0, 1.0, fly_dur
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		main_tween.parallel().tween_property(paper, "rotation_degrees", target_rot, fly_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		main_tween.parallel().tween_property(paper, "scale", Vector2(0.4, 0.4), fly_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# Stage 3: Soft Impact at counter
		var paper_index := i
		main_tween.chain().tween_callback(func():
			if is_instance_valid(paper):
				_spawn_landing_sparkle(target_pos)
				paper.queue_free()

			var step_count := start_count + int(round(float(count_diff) * float(paper_index + 1) / float(num_flyers)))
			step_count = clampi(step_count, 0, new_total)
			update_counter(step_count)
			_punch_counter_btn()
		)

func _create_paper_node() -> Control:
	var paper := TextureRect.new()
	var mail_tex = load("res://assets/objects/inventory_mail.png") as Texture2D
	if mail_tex:
		paper.texture = mail_tex
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	paper.custom_minimum_size = Vector2(40, 26)
	paper.size = Vector2(40, 26)
	paper.pivot_offset = Vector2(20, 13)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return paper

func _punch_counter_btn() -> void:
	if not letter_counter_btn:
		return
	var target_node: Control = letter_counter_btn.get_node_or_null("Content") as Control
	if not target_node:
		target_node = letter_counter_btn

	var mail_icon: Control = target_node.get_node_or_null("MailIcon") as Control

	# Center pivot over icon area
	target_node.pivot_offset = Vector2(28.0, target_node.size.y * 0.5)

	# Step 1: Explosive impact burst (scale + tilt)
	var t1 := create_tween().set_parallel(true)
	t1.tween_property(target_node, "scale", Vector2(1.32, 1.25), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t1.tween_property(target_node, "rotation_degrees", -7.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_instance_valid(mail_icon):
		mail_icon.pivot_offset = mail_icon.size * 0.5
		t1.tween_property(mail_icon, "scale", Vector2(1.35, 1.35), 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Step 2: Elastic recoil & counter-tilt
	var t2 := create_tween().set_parallel(true)
	t2.tween_property(target_node, "scale", Vector2(0.95, 0.95), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t2.tween_property(target_node, "rotation_degrees", 4.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(mail_icon):
		t2.tween_property(mail_icon, "scale", Vector2(0.9, 0.9), 0.10)

	# Step 3: Elastic bounce settlement
	var t3 := create_tween().set_parallel(true)
	t3.tween_property(target_node, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t3.tween_property(target_node, "rotation_degrees", 0.0, 0.14).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if is_instance_valid(mail_icon):
		t3.tween_property(mail_icon, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _spawn_landing_sparkle(pos: Vector2) -> void:
	if not control:
		return
	for s in range(8):
		var p := ColorRect.new()
		p.color = Color(1.0, 0.88, 0.35, 1.0) # Bright golden sparkle
		p.size = Vector2(5, 5)
		p.position = pos - Vector2(2.5, 2.5)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.add_child(p)

		var angle := float(s) * (PI * 2.0 / 8.0) + randf_range(-0.2, 0.2)
		var dist := randf_range(28.0, 45.0)
		var sparkle_offset := Vector2(cos(angle), sin(angle)) * dist

		var tween := create_tween().set_parallel(true)
		tween.tween_property(p, "position", pos + sparkle_offset, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(p, "modulate:a", 0.0, 0.30)
		tween.tween_property(p, "scale", Vector2(0.1, 0.1), 0.30)
		tween.chain().tween_callback(func():
			if is_instance_valid(p):
				p.queue_free()
		)

func _on_counter_pressed() -> void:
	if letter_inventory:
		letter_inventory.open_inventory()

func _on_menu_pressed() -> void:
	var existing = get_tree().current_scene.get_node_or_null("MainMenu")
	if not is_instance_valid(existing):
		SaveManager.save_current_state()
		var menu_scene = load("res://scenes/ui/main_menu.tscn")
		if menu_scene:
			get_tree().current_scene.add_child(menu_scene.instantiate())

func _on_debug_intro_pressed() -> void:
	var current = get_tree().current_scene
	if current and current.has_method("play_full_intro_sequence"):
		current.play_full_intro_sequence()

func _on_debug_end_pressed() -> void:
	LetterManager.collect_letter_bundle(1, 21)
	var current = get_tree().current_scene
	var finish_trigger = current.get_node_or_null("FinishTrigger") if current else null
	var player = current.get_node_or_null("Player") if current else null
	
	if finish_trigger and player:
		player.global_position = finish_trigger.global_position
		finish_trigger._play_finish_sequence(player)
	else:
		_on_menu_pressed()
