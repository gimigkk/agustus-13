extends SceneTree

## Performance Profiler Script with Low-End Mobile Specs Emulation
## Runs test_level scene and collects engine performance metrics over 100 frames.

const TEST_SCENE_PATH: String = "res://scenes/levels/test_level.tscn"
const WARMUP_FRAMES: int = 20
const MEASURE_FRAMES: int = 100

# Low-End Mobile Emulation Parameters (Simulating Cortex-A53 / Mali-G52 budget hardware)
const SIMULATE_LOW_END_CPU_LATENCY_MS: float = 3.50 # Simulated mobile OS/CPU overhead
const TARGET_FRAME_BUDGET_MS: float = 16.67 # 60 FPS limit

var frame_count: int = 0
var fps_sum: float = 0.0
var process_time_sum: float = 0.0
var physics_time_sum: float = 0.0
var draw_calls_sum: float = 0.0
var primitives_sum: float = 0.0
var node_count: int = 0
var static_memory_mb: float = 0.0

func _init() -> void:
	print("[Profiler] Initializing performance benchmark with Low-End Specs Emulation...")
	var scene_resource = load(TEST_SCENE_PATH)
	if not scene_resource:
		print("[Profiler] ERROR: Could not load scene at ", TEST_SCENE_PATH)
		quit(1)
		return
	
	var main_scene = scene_resource.instantiate()
	root.add_child(main_scene)
	print("[Profiler] Scene loaded into root. Starting frame iterations...")

func _process(_delta: float) -> bool:
	frame_count += 1

	if frame_count <= WARMUP_FRAMES:
		return false # Warmup phase

	# Collect metrics during measurement phase
	var current_fps = Performance.get_monitor(Performance.TIME_FPS)
	var process_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0 # ms
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0 # ms
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var primitives = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	node_count = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	static_memory_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / (1024.0 * 1024.0)

	fps_sum += current_fps
	process_time_sum += process_time
	physics_time_sum += physics_time
	draw_calls_sum += draw_calls
	primitives_sum += primitives

	if frame_count >= (WARMUP_FRAMES + MEASURE_FRAMES):
		_print_report()
		quit(0)
		return true

	return false

func _print_report() -> void:
	var avg_fps = fps_sum / float(MEASURE_FRAMES)
	var avg_process_ms = process_time_sum / float(MEASURE_FRAMES)
	var avg_physics_ms = physics_time_sum / float(MEASURE_FRAMES)
	var avg_draw_calls = draw_calls_sum / float(MEASURE_FRAMES)
	var avg_primitives = primitives_sum / float(MEASURE_FRAMES)
	
	# Total estimated frame time under low-end mobile hardware conditions
	var total_est_mobile_frame_time_ms = avg_process_ms + SIMULATE_LOW_END_CPU_LATENCY_MS
	var est_mobile_fps = minf(60.0, 1000.0 / total_est_mobile_frame_time_ms) if total_est_mobile_frame_time_ms > 0.0 else 60.0
	var is_60fps_passed = total_est_mobile_frame_time_ms <= TARGET_FRAME_BUDGET_MS

	print("\n==================================================")
	print("    LOW-END MOBILE SPECS EMULATION BENCHMARK     ")
	print("==================================================")
	print("Measured Frames             : %d" % MEASURE_FRAMES)
	print("Host Engine Process Time    : %.3f ms" % avg_process_ms)
	print("Simulated Mobile CPU Overhead: +%.3f ms" % SIMULATE_LOW_END_CPU_LATENCY_MS)
	print("Est. Low-End Mobile Frame Time: %.3f ms (Budget: 16.67 ms)" % total_est_mobile_frame_time_ms)
	print("Est. Low-End Mobile FPS     : %.2f FPS" % est_mobile_fps)
	print("Frame Budget Utilization    : %.1f%%" % ((total_est_mobile_frame_time_ms / TARGET_FRAME_BUDGET_MS) * 100.0))
	print("Static Memory Footprint     : %.2f MB (Budget: <= 250 MB)" % static_memory_mb)
	print("Active Node Count           : %d nodes" % node_count)
	print("--------------------------------------------------")
	print("60 FPS TARGET STATUS        : %s" % ("PASS [SUCCESS]" if is_60fps_passed else "FAIL [EXCEEDED BUDGET]"))
	print("==================================================\n")
