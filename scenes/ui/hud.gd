extends CanvasLayer

## HUD script managing in-game counter button, menu, and inventory modal
@onready var control: Control = $Control
@onready var letter_counter_btn: Button = $Control/TopBar/MarginContainer/HBoxContainer/LetterCounterBtn
@onready var menu_btn: Control = $Control/TopBar/MarginContainer/HBoxContainer/MenuBtn
@onready var letter_inventory: CanvasLayer = $LetterInventory

var current_displayed_count: int = 0

func _ready() -> void:
	if control:
		control.show()
		
	var lm = get_node_or_null("/root/LetterManager")
	var count: int = lm.get_collected_count() if lm else 0
	current_displayed_count = count
	update_counter(count)
	
	if lm:
		if not lm.letter_collected.is_connected(_on_letter_collected):
			lm.letter_collected.connect(_on_letter_collected)
	if letter_counter_btn:
		if not letter_counter_btn.pressed.is_connected(_on_counter_pressed):
			letter_counter_btn.pressed.connect(_on_counter_pressed)
	if menu_btn:
		if menu_btn.has_signal("pressed") and not menu_btn.pressed.is_connected(_on_menu_pressed):
			menu_btn.pressed.connect(_on_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_on_debug_end_pressed()
		elif event.keycode == KEY_F2:
			_on_debug_intro_pressed()

func update_counter(count: int) -> void:
	if letter_counter_btn:
		var lm = get_node_or_null("/root/LetterManager")
		var total_available: int = lm.TOTAL_LETTERS if lm else 21
		var safe_count: int = clampi(count, 0, total_available)
		current_displayed_count = safe_count
		letter_counter_btn.text = "%d / %d Letters" % [safe_count, total_available]

func show_summit_celebration() -> void:
	var celeb_scene = load("res://scenes/ui/summit_celebration.tscn")
	if celeb_scene:
		var celeb = celeb_scene.instantiate()
		add_child(celeb)

func show_incomplete_prompt(collected: int, required: int) -> void:
	var popup_scene = load("res://scenes/ui/letter_popup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		add_child(popup)
		if popup.has_method("display_message"):
			popup.display_message("Summit Reached!", "You made it to the top! But you still need to collect all %d letters to unlock the birthday surprise! (%d/%d collected)" % [required, collected, required])

func _on_letter_collected(_id: int, _msg: String, total: int, collect_pos: Vector2 = Vector2.ZERO) -> void:
	_animate_flying_papers(collect_pos, total)

func _animate_flying_papers(collect_world_pos: Vector2, new_total: int) -> void:
	if not letter_counter_btn or not control:
		update_counter(new_total)
		return

	# Calculate screen target position (center/left area of counter button)
	var target_rect := letter_counter_btn.get_global_rect()
	var target_pos := target_rect.position + Vector2(30.0, target_rect.size.y * 0.5)

	# Calculate screen start position
	var start_pos: Vector2
	if collect_world_pos != Vector2.ZERO and get_viewport():
		start_pos = get_viewport().get_canvas_transform() * collect_world_pos
	elif get_viewport():
		start_pos = get_viewport().get_visible_rect().size * 0.5
	else:
		start_pos = Vector2(200.0, 300.0)

	var start_count: int = current_displayed_count
	var count_diff: int = max(1, new_total - start_count)

	# Spawn exactly 3 flying papers
	for i in range(3):
		var paper := _create_paper_node()
		control.add_child(paper)

		paper.global_position = start_pos - paper.pivot_offset
		paper.scale = Vector2(0.3, 0.3)

		var delay := float(i) * 0.08
		var burst_angle := randf_range(-PI * 0.75, -PI * 0.25)
		var burst_dist := randf_range(35.0, 65.0)
		var burst_pos := start_pos + Vector2(cos(burst_angle), sin(burst_angle)) * burst_dist

		# Mid control point for quadratic bezier arc towards top-left counter
		var mid := (burst_pos + target_pos) * 0.5
		var arc_offset := Vector2(randf_range(-60.0, -120.0), randf_range(-80.0, -140.0))
		var control_pt := mid + arc_offset

		var main_tween := create_tween()
		main_tween.tween_interval(delay)

		# 1. Burst stage (0.15s)
		var initial_rot := randf_range(-30.0, 30.0)
		main_tween.tween_property(paper, "global_position", burst_pos - paper.pivot_offset, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		main_tween.parallel().tween_property(paper, "scale", Vector2(1.25, 1.25), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		main_tween.parallel().tween_property(paper, "rotation_degrees", initial_rot, 0.15)

		# 2. Bezier Arc Flight stage (0.55s)
		var fly_dur := 0.55
		var total_spin := randf_range(360.0, 540.0) * (1.0 if randf() > 0.5 else -1.0)
		var target_rot := initial_rot + total_spin

		# Animate along quadratic bezier curve using tween_method
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

		main_tween.parallel().tween_property(paper, "rotation_degrees", target_rot, fly_dur)
		main_tween.parallel().tween_property(paper, "scale", Vector2(0.6, 0.6), fly_dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# 3. Impact stage at target counter
		var paper_index := i
		main_tween.chain().tween_callback(func():
			if is_instance_valid(paper):
				_spawn_landing_sparkle(target_pos)
				paper.queue_free()

			# Increment counter smoothly on each paper landing
			var step_count := start_count + int(round(float(count_diff) * float(paper_index + 1) / 3.0))
			step_count = clampi(step_count, 0, new_total)
			update_counter(step_count)

			# Counter button punch scale bounce
			_punch_counter_btn()
		)

func _create_paper_node() -> Control:
	var paper := Control.new()
	paper.custom_minimum_size = Vector2(22, 28)
	paper.size = Vector2(22, 28)
	paper.pivot_offset = Vector2(11, 14)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Shadow
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.size = Vector2(22, 28)
	shadow.position = Vector2(2, 2)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(shadow)

	# Main Paper Body
	var body := ColorRect.new()
	body.color = Color(0.98, 0.96, 0.90) # Warm paper cream
	body.size = Vector2(22, 28)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(body)

	# Paper Red Top Stripe
	var top_stripe := ColorRect.new()
	top_stripe.color = Color(0.85, 0.3, 0.3)
	top_stripe.size = Vector2(22, 4)
	top_stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(top_stripe)

	# Cute Letter Fold / Icon Label
	var label := Label.new()
	label.text = "✉"
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	label.position = Vector2(3, 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paper.add_child(label)

	return paper

func _punch_counter_btn() -> void:
	if not letter_counter_btn:
		return
	letter_counter_btn.pivot_offset = letter_counter_btn.size * 0.5
	var tween := create_tween()
	tween.tween_property(letter_counter_btn, "scale", Vector2(1.15, 1.15), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(letter_counter_btn, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _spawn_landing_sparkle(pos: Vector2) -> void:
	if not control:
		return
	for s in range(5):
		var p := ColorRect.new()
		p.color = Color(1.0, 0.9, 0.4, 1.0) # Golden sparkle
		p.size = Vector2(4, 4)
		p.position = pos - Vector2(2, 2)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		control.add_child(p)

		var offset := Vector2(randf_range(-25, 25), randf_range(-25, 25))
		var tween := create_tween().set_parallel(true)
		tween.tween_property(p, "position", pos + offset, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(p, "modulate:a", 0.0, 0.25)
		tween.tween_property(p, "scale", Vector2(0.1, 0.1), 0.25)
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
		var sm = get_node_or_null("/root/SaveManager")
		if sm and sm.has_method("save_current_state"):
			sm.save_current_state()
			
		var menu_scene = load("res://scenes/ui/main_menu.tscn")
		if menu_scene:
			var menu = menu_scene.instantiate()
			get_tree().current_scene.add_child(menu)


func _on_debug_intro_pressed() -> void:
	var current = get_tree().current_scene
	if current and current.has_method("play_intro_sequence"):
		current.play_intro_sequence()

func _on_debug_end_pressed() -> void:
	# Grant all 21 letters for testing
	var lm = get_node_or_null("/root/LetterManager")
	if lm:
		lm.collect_letter_bundle(1, 21)
		
	# Find FinishTrigger and trigger cutscene directly
	var current = get_tree().current_scene
	var finish_trigger = current.get_node_or_null("FinishTrigger") if current else null
	var player = current.get_node_or_null("Player") if current else null
	
	if finish_trigger and player and finish_trigger.has_method("_play_finish_sequence"):
		player.global_position = finish_trigger.global_position
		finish_trigger._play_finish_sequence(player)
	else:
		show_summit_celebration()
