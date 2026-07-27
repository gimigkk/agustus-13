extends Node2D

## Lightweight visibility culler for Sprite2D slice children.
## Hides offscreen slices to eliminate unnecessary GPU draw calls.
## Uses a frame skip to reduce CPU overhead on low-end devices.

const MARGIN: float = 300.0  # Vertical buffer before hiding (px)
var _frame_counter: int = 0

func _process(_delta: float) -> void:
	# Only cull every 3rd frame — slices are large, player moves slowly
	_frame_counter += 1
	if _frame_counter % 3 != 0:
		return

	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cam:
		return

	var vp_h: float = get_viewport_rect().size.y
	var cam_y: float = cam.global_position.y
	var cam_top: float = cam_y - vp_h * 0.5 - MARGIN
	var cam_bottom: float = cam_y + vp_h * 0.5 + MARGIN

	for child in get_children():
		if child is CanvasItem:
			var half_h: float = 600.0  # Fallback margin height
			if child is Sprite2D and child.texture:
				half_h = child.texture.get_height() * 0.5 * child.scale.y
			var top: float = child.global_position.y - half_h
			var bottom: float = child.global_position.y + half_h
			var is_visible: bool = bottom > cam_top and top < cam_bottom
			if child.visible != is_visible:
				child.visible = is_visible
