### CodexOverlayMain.gd
extends Node2D

@onready var stage: Control = $CanvasLayer/Stage

@onready var start_marker: Marker2D = $CanvasLayer/Markers/StartMarker
@onready var load_marker: Marker2D = $CanvasLayer/Markers/LoadMarker
@onready var focus_marker: Marker2D = $CanvasLayer/Markers/FocusMarker
@onready var offload_marker: Marker2D = $CanvasLayer/Markers/OffloadMarker

@onready var loader: ImageLoader = $ImageLoader

# Timing Model
@export var travel_time_s: float = 10.0		# time from start to offload
@export var spacing_px: float = 260.0		# how far apart items appear
@export var focus_scale: float = 1.25		# zoom at focus
@export var	focus_width_t: float = 0.12		# how wide the focus region is

const ITEM_SIZE := Vector2(512, 512)

var image_queue: Array[Dictionary] = []
var load_index := 0
var cycle_index := 0
var has_started := false

# Spawn scheduling
var last_spawn_ms: int = 0
var spawn_interval_s: float = 1.0
var live_items: Array[ScrollingItem] = []


func _ready() -> void:
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_recompute_spawn_interval()
	
	loader.images_ready.connect(_on_images_ready)
	loader.image_loaded.connect(_on_image_loaded)
	loader.all_images_loaded.connect(_on_all_images_loaded)
	
	print("READY: requesting images.json")
	loader.request_images("http://localhost:3030/overlay/images.json")


func _on_images_ready(queue: Array) -> void:
	# Shallow copy is fine; dictionaries are shared
	image_queue = queue
	has_started = false
	cycle_index = 0
	print("Images metadata received:", image_queue.size())


func _on_image_loaded(index: int, texture: Texture2D) -> void:
	if index < image_queue.size():
		image_queue[index]["texture"] = texture
	print("Image loaded:", index)


func _on_all_images_loaded() -> void:
	print("All images fully loaded")


func _recompute_spawn_interval() -> void:
	var start_pos: Vector2 = start_marker.global_position
	var off_pos: Vector2 = offload_marker.global_position
	var distance: float = start_pos.distance_to(off_pos)
	
	if distance <= 0.001:
		spawn_interval_s = 8.0
		return
	
	# "spacing_px" worth of travel time
	spawn_interval_s = (spacing_px / distance) * travel_time_s


func _process(delta: float) -> void:
	var now_ms: int = Time.get_ticks_msec()
	
	_update_items(now_ms)
	_try_spawn(now_ms)
	
	return


func _update_items(now_ms: int) -> void:	
	#iterate backwards so we can remove safely
	for i in range (live_items.size() -1, -1, -1):
		var item := live_items[i]
		if not item.update_item(now_ms):
			item.queue_free()
			live_items.remove_at(i)

	return


func _try_spawn(now_ms: int) -> void:
	if image_queue.is_empty():
		return
	
	# require at least one texture in queue before starting
	if not has_started:
		if not image_queue[0].has("texture"):
			return
		has_started = true
		last_spawn_ms = now_ms - int(spawn_interval_s * 1000.0)		# allow immediate spawn
		
	var elapsed_s := float(now_ms - last_spawn_ms) / 1000.0
	if elapsed_s < spawn_interval_s:
		return
		
	#find next textured entry
	var attempts: int = 0
	while attempts < image_queue.size():
		var info := image_queue[cycle_index]
		cycle_index = (cycle_index + 1) % image_queue.size()
		attempts += 1
		
		var tex: Texture2D = info.get("texture", null)
		if tex == null:
			continue
		
		var item := ScrollingItem.new()
		item.name = info.get("title", "???")

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
		
		_configure_item_visuals(item, info.get("title", "???"), tex)
		stage.add_child(item)
		live_items.append(item)
		last_spawn_ms = now_ms
		return


func _marker_t(marker_pos: Vector2, start_pos: Vector2, end_pos: Vector2) -> float:
	# Projects marker onto the start->end segment, returns normalized t
	var v := end_pos - start_pos
	var len2 := v.length_squared()
	if len2 <= 0.000001:
		return 0.0
	var t := (marker_pos - start_pos).dot(v) / len2
	return clamp(t, 0.0, 1.0)


func _configure_item_visuals(
	item: ScrollingItem,
	title: String,
	texture: Texture2D
) -> void:
	item.size = ITEM_SIZE
	item.custom_minimum_size = ITEM_SIZE
	
	var panel :=StyleBoxFlat.new()
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
	return
