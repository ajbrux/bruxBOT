### SpawnController.gd
extends Node
class_name SpawnController

@export var stage_path: NodePath = ^"../CanvasLayer/Stage"
@export var start_marker_path: NodePath = ^"../CanvasLayer/Markers/StartMarker"
@export var load_marker_path: NodePath = ^"../CanvasLayer/Markers/LoadMarker"
@export var focus_marker_path: NodePath = ^"../CanvasLayer/Markers/FocusMarker"
@export var offload_marker_path: NodePath = ^"../CanvasLayer/Markers/OffloadMarker"

# Timing Model
@export var travel_time_s: float = 10
@export var spacing_px: float = 260
@export var focus_scale: float = 1.25
@export var focus_width_t: float = 0.12

const ITEM_SIZE := Vector2(512, 512)

var stage: Control
var start_marker: Marker2D
var load_marker: Marker2D
var focus_marker: Marker2D
var offload_marker: Marker2D

var image_queue: Array[Dictionary] = []
var cycle_index: int = 0
var has_started: bool = false

var last_spawn_ms: int = 0
var spawn_interval_s: float = 1.0
var live_items: Array[ScrollingItem] = []


func _ready() -> void:
	stage = get_node(stage_path) as Control
	start_marker = get_node(start_marker_path) as Marker2D
	load_marker = get_node(load_marker_path) as Marker2D
	focus_marker = get_node(focus_marker_path) as Marker2D
	offload_marker = get_node(offload_marker_path) as Marker2D
	
	if stage:
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_recompute_spawn_interval()


func set_queue(queue: Array) -> void:
	image_queue = queue
	cycle_index = 0
	has_started = false
	last_spawn_ms = 0


func on_image_loaded(index: int, texture: Texture2D) -> void:
	if index >= 0 and index < image_queue.size():
		image_queue[index]["texture"] = texture


func _process(delta: float) -> void:
	var now_ms: int = Time.get_ticks_msec()
	_update_items(now_ms)
	_try_spawn(now_ms)


func _recompute_spawn_interval() -> void:
	if not start_marker or not offload_marker:
		spawn_interval_s = 1.0
		return
	
	var start_pos: Vector2 = start_marker. global_position
	var off_pos: Vector2 = offload_marker.global_position
	var distance: float = start_pos.distance_to(off_pos)
	
	if distance <= 0.001:
		spawn_interval_s = 8.0
		return
	
	spawn_interval_s = (spacing_px / distance) * travel_time_s


func _update_items(now_ms: int) -> void:
	for i in range(live_items.size() - 1, -1, -1):
		var item := live_items[i]
		if not item.update_item(now_ms):
			item.queue_free()
			live_items.remove_at(i)


func _try_spawn(now_ms: int) -> void:
	if image_queue.is_empty():
		return
	
	if not has_started:
		var found := false
		
		for d in image_queue:
			if d.has("texture") and d["texture"] != null:
				found = true
				break
		
		if not found:
			return
		
		has_started = true
		last_spawn_ms = now_ms - int(spawn_interval_s * 1000.0)		#allow immediate spawn
	
	var elapsed_s := float(now_ms - last_spawn_ms) / 1000.0
	if elapsed_s < spawn_interval_s:
		return
	
	var attempts: int = 0
	while attempts < image_queue.size():
		var info := image_queue[cycle_index]
		cycle_index = (cycle_index + 1) % image_queue.size()
		attempts += 1
		
		var tex: Texture2D = info.get("texture", null)
		if tex == null:
			continue
		
		var title: String = info.get("title", "???")
		
		var item := ScrollingItem.new()
		item.name = title
		
		item.setup(
			now_ms,
			travel_time_s,
			start_marker.global_position,
			offload_marker.global_position,
			_marker_t(load_marker.global_position, start_marker.global_position, offload_marker.global_position),
			_marker_t(focus_marker.global_position, start_marker.global_position, offload_marker.global_position),
			focus_width_t,
			focus_scale
		)
		
		_configure_item_visuals(item, title, tex)
		
		stage.add_child(item)
		live_items.append(item)
		
		last_spawn_ms = now_ms
		return


func _marker_t(marker_pos: Vector2, start_pos: Vector2, end_pos: Vector2) -> float:
	var v := end_pos - start_pos
	var len2 := v.length_squared()
	if len2 <= 0.000001:
		return 0.0
	var t := (marker_pos - start_pos).dot(v) / len2
	return clamp(t, 0.0, 1.0)


func _configure_item_visuals(item: ScrollingItem, title: String, texture: Texture2D) -> void:
	item.size = ITEM_SIZE
	item.custom_minimum_size = ITEM_SIZE
	
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.15, 0.15, 0.15, 0.85)
	item.add_theme_stylebox_override("panel", panel)
	
	var label := Label.new()
	label.text = "!" + title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_right = 1
	label.offset_bottom = 48
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.RED)
	item.add_child(label)
	
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.anchor_right = 1
	sprite.anchor_bottom = 1
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item.add_child(sprite)
