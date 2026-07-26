@tool
extends SceneTree

func _init() -> void:
	print("[LevelExporter] Starting 1:1 exact scale level image export...")
	_export_level()
	quit(0)

func _export_level() -> void:
	var level_scene: PackedScene = load("res://scenes/levels/test_level.tscn")
	if not level_scene:
		print("Error: Could not load test_level.tscn")
		return

	var level: Node2D = level_scene.instantiate() as Node2D
	
	# Level bounds in Godot 2D World Space:
	# Horizontal: X from -400 to +400 (Width: 800 units -> 800 pixels)
	# Vertical: Y from -4150 to +1300 (Height: 5450 units -> 5450 pixels)
	# 1 Godot unit = 1 Image pixel (1:1 exact mapping)
	var bounds_left: float = -400.0
	var bounds_right: float = 400.0
	var bounds_top: float = -4150.0
	var bounds_bottom: float = 1300.0

	var width: int = int(bounds_right - bounds_left) # 800px
	var height: int = int(bounds_bottom - bounds_top) # 5450px

	# Create image buffer
	var img: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	var bg_color = Color(0.12, 0.12, 0.18, 1.0) # Game dark background
	img.fill(bg_color)

	var platform_count: int = 0

	# Render Environment platforms
	var env = level.get_node_or_null("Environment")
	if env:
		for child in env.get_children():
			if child is Node2D:
				_render_platform(img, child, bounds_left, bounds_top)
				platform_count += 1

	# Render Collectibles (Letters)
	var col = level.get_node_or_null("Collectibles")
	if col:
		for child in col.get_children():
			if child is Node2D:
				_render_marker(img, child, Color(1.0, 0.84, 0.0, 1.0), Vector2(24, 24), bounds_left, bounds_top)

	# Render Finish Trigger
	var finish = level.get_node_or_null("FinishTrigger")
	if finish is Node2D:
		_render_marker(img, finish, Color(0.2, 0.9, 0.4, 1.0), Vector2(100, 40), bounds_left, bounds_top)

	# Render Banana Peel
	var banana = level.get_node_or_null("BananaPeel")
	if banana is Node2D:
		_render_marker(img, banana, Color(1.0, 0.5, 0.0, 1.0), Vector2(30, 30), bounds_left, bounds_top)

	# Render Walk Target
	var walk_target = level.get_node_or_null("WalkTarget")
	if walk_target is Node2D:
		_render_marker(img, walk_target, Color(0.2, 0.7, 0.9, 1.0), Vector2(60, 24), bounds_left, bounds_top)

	# Render Fall Target
	var fall_target = level.get_node_or_null("FallTarget")
	if fall_target is Node2D:
		_render_marker(img, fall_target, Color(0.2, 0.8, 0.4, 1.0), Vector2(60, 24), bounds_left, bounds_top)

	# Render Player Start Marker
	var player = level.get_node_or_null("Player")
	if player is Node2D:
		_render_marker(img, player, Color(0.9, 0.2, 0.2, 1.0), Vector2(32, 48), bounds_left, bounds_top)

	# Ensure exports directory exists
	DirAccess.make_dir_recursive_absolute("res://exports")

	# Save full level PNG
	var output_path = "res://exports/full_level.png"
	img.save_png(output_path)
	
	print("[LevelExporter] Success! 1:1 Level Map saved to: ", output_path)
	print("  • Canvas Size: ", width, "x", height, " pixels")
	print("  • Scale Ratio: 1 Godot 2D Unit = 1 PNG Pixel (1:1 Exact Match)")
	print("  • Platforms Rendered: ", platform_count)

	level.free()

func _render_platform(img: Image, node: Node2D, bounds_left: float, bounds_top: float) -> void:
	var pos: Vector2 = node.position
	var scale: Vector2 = node.scale
	
	var base_size: Vector2 = Vector2(200, 30)
	var color: Color = Color(0.35, 0.4, 0.5, 1.0)
	
	if "size" in node:
		base_size = node.get("size")
	if "color" in node:
		color = node.get("color")
		
	var actual_size: Vector2 = Vector2(abs(base_size.x * scale.x), abs(base_size.y * scale.y))
	var top_left_world: Vector2 = pos - (actual_size / 2.0)
	
	# Exact 1:1 pixel mapping: pixel_offset = world_pos - bounds_origin
	var img_x: int = int(round(top_left_world.x - bounds_left))
	var img_y: int = int(round(top_left_world.y - bounds_top))
	var img_w: int = int(round(actual_size.x))
	var img_h: int = int(round(actual_size.y))

	_fill_rect(img, img_x, img_y, img_w, img_h, color)

func _render_marker(img: Image, node: Node2D, color: Color, size: Vector2, bounds_left: float, bounds_top: float) -> void:
	var pos: Vector2 = node.position
	var img_x: int = int(round(pos.x - (size.x / 2.0) - bounds_left))
	var img_y: int = int(round(pos.y - (size.y / 2.0) - bounds_top))
	_fill_rect(img, img_x, img_y, int(size.x), int(size.y), color)

func _fill_rect(img: Image, start_x: int, start_y: int, w: int, h: int, color: Color) -> void:
	var img_w = img.get_width()
	var img_h = img.get_height()
	
	var min_x = clampi(start_x, 0, img_w)
	var max_x = clampi(start_x + w, 0, img_w)
	var min_y = clampi(start_y, 0, img_h)
	var max_y = clampi(start_y + h, 0, img_h)
	
	for y in range(min_y, max_y):
		for x in range(min_x, max_x):
			img.set_pixel(x, y, color)
