### SpawnController.gd
extends Node
class_name SpawnController

@export var stage_path: NodePath = ^"../CanvasLayer/Stage"
@export var start_marker_path: NodePath = ^"../CanvasLayer/Markers/StartMarker"
@export var load_marker_path: NodePath = ^"../CanvasLayer/Markers/LoadMarker"
@export var focus_marker_path: NodePath = ^"../CanvasLayer/Markers/FocusMarker"
@export var offload_marker_path: NodePath = ^"../CanvasLayer/Markers/OffloadMarker"
@export var display_marker_path: NodePath = ^"../CanvasLayer/Markers/DisplayMarker"

@export var travel_time_s: float = 19
@export var spacing_px: float = 170
@export var focus_scale: float = 1
@export var focus_width_t: float = 0.35

var display_marker: Marker2D
const ITEM_SIZE := Vector2(300, 160)

var scroll_speed_multiplier: float = 1.0
var stage: Control
var start_marker: Marker2D
var load_marker: Marker2D
var focus_marker: Marker2D
var offload_marker: Marker2D

var image_queue: Array[Dictionary] = []
var called_item: ScrollingItem = null
var cycle_index: int = 0
var has_started: bool = false

var spawn_elapsed_s: float = 0.0
var spawn_interval_s: float = 1.0
var live_items: Array[ScrollingItem] = []


func _ready() -> void:
	stage = get_node(stage_path) as Control
	start_marker = get_node(start_marker_path) as Marker2D
	load_marker = get_node(load_marker_path) as Marker2D
	focus_marker = get_node(focus_marker_path) as Marker2D
	display_marker = get_node(display_marker_path) as Marker2D
	offload_marker = get_node(offload_marker_path) as Marker2D
	
	if stage:
		stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_recompute_spawn_interval()


func set_queue(queue: Array) -> void:
	image_queue = queue
	cycle_index = 0
	has_started = false
	spawn_elapsed_s = 0.0


func on_image_loaded(index: int, texture: Texture2D) -> void:
	if index >= 0 and index < image_queue.size():
		image_queue[index]["texture"] = texture


func _process(delta: float) -> void:
	spawn_elapsed_s += delta * scroll_speed_multiplier
	_update_item(delta)
	_try_spawn()


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


func _update_item(delta: float) -> void:
	for i in range(live_items.size() - 1, -1, -1):
		var item := live_items[i]
		if not item.update_item(delta, scroll_speed_multiplier):
			item.queue_free()
			live_items.remove_at(i)
	
	if called_item and called_item.call_state == ScrollingItem.CallState.NORMAL:
		scroll_speed_multiplier = 1.0
		called_item = null
		print("Call cycle complete. Scroll restored.")


func _try_spawn() -> void:
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
		spawn_elapsed_s = spawn_interval_s		#allow immediate spawn
	
	if spawn_elapsed_s < spawn_interval_s:
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
		
		spawn_elapsed_s = 0.0
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
	panel.bg_color = Color.TRANSPARENT
	panel.content_margin_left = 0
	panel.content_margin_right = 0
	panel.content_margin_top = 0
	panel.content_margin_bottom = 0
	item.add_theme_stylebox_override("panel", panel)
	
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	var label_center := CenterContainer.new()
	label_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label := Label.new()
	label.text = "!" + title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	#label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.add_theme_font_size_override("font_size", 29)
	# label.add_theme_color_override("font_color", Color.CRIMSON)
	
	label_center.add_child(label)
	item.label = label
	vbox.add_child(label_center)
	
	var sprite_center := CenterContainer.new()
	sprite_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.custom_minimum_size = Vector2(115, 115)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	sprite_center.add_child(sprite)
	vbox.add_child(sprite_center)
	
	item.add_child(vbox)


func fire_first_armed() -> void:
	if called_item != null:
		return
	
	for item in live_items:
		if item.focused and item.call_state == ScrollingItem.CallState.NORMAL:
			called_item = item
			item.start_call(display_marker.global_position)
			scroll_speed_multiplier = 0.2
			return


func _input(event) -> void:
	if event.is_action_pressed("ui_accept"):
		fire_first_armed()
