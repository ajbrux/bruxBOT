extends Node2D

@onready var stage: Control = $CanvasLayer/Stage

@onready var start_marker: Marker2D = $CanvasLayer/Markers/StartMarker
@onready var load_marker: Marker2D = $CanvasLayer/Markers/LoadMarker
@onready var focus_marker: Marker2D = $CanvasLayer/Markers/FocusMarker
@onready var offload_marker: Marker2D = $CanvasLayer/Markers/OffloadMarker


@onready var http_request: HTTPRequest = $ImageRequest
@onready var image_fetcher: HTTPRequest = $ImageFetcher

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

class ItemState:
	var node: Panel
	var spawn_ms: int
	var loaded: bool = true
	var focused: bool = false
	
	func _init(n: Panel, t_ms: int) -> void:
		node = n
		spawn_ms = t_ms

var live_items: Array[ItemState] = []


func _ready() -> void:
	# Stage sanity
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# compute spawn interval from spacing_px + travel_time
	_recompute_spawn_interval()
	
	print("READY: requesting images.json")
	http_request.request("http://localhost:3030/overlay/images.json")
	
	
func _recompute_spawn_interval() -> void:
	var start_pos: Vector2 = start_marker.global_position
	var off_pos: Vector2 = offload_marker.global_position
	var distance: float = start_pos.distance_to(off_pos)
	
	if distance <= 0.001:
		spawn_interval_s = 1.0
		return
	
	# "spacing_px" worth of travel time
	spawn_interval_s = (spacing_px / distance) * travel_time_s


func _process(delta: float) -> void:
	var now_ms: int = Time.get_ticks_msec()
	
	_update_items(now_ms)
	_try_spawn(now_ms)


func _update_items(now_ms: int) -> void:
	var start_pos := start_marker.global_position
	var off_pos := offload_marker.global_position
	var load_t := _marker_t(load_marker.global_position, start_pos, off_pos)
	var focus_t := _marker_t(focus_marker.global_position, start_pos, off_pos)
	
	#iterate backwards so we can remove safely
	for i in range (live_items.size() -1, -1, -1):
		var st := live_items[i]
		
		var age_s := float(now_ms - st.spawn_ms) / 1000.0
		var t := age_s / travel_time_s
		
		if t >= 1.0:
			#offload
			st.node.queue_free()
			live_items.remove_at(i)
			continue
		
		t = clamp(t, 0.0, 1.0)
		
		#position along line Start -> Offload
		var p := start_pos.lerp(off_pos, t)
		
		# Place item centered on p (Panels use top-left position)
		st.node.global_position = p - ITEM_SIZE * 0.5
		
		# Load trigger (semantic hook)
		if (not st.loaded) and t >= load_t:
			st.loaded = true
			#You could populate textures here if you spawn placeholders
		
		# Focus scaling around focus_t
		var focus_amt: float = 1.0 - (abs(t - focus_t) / max(focus_width_t, 0.0001))
		focus_amt = clamp(focus_amt, 0.0, 1.0)
		
		var s: float = lerp(1.0, focus_scale, focus_amt)
		st.node.scale = Vector2(s, s)
		
		# If you want a single "entered focus" event:
		if (not st.focused) and t >= focus_t:
			st.focused = true
			#fire focus event here


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
		
		var item := create_image_item(info.get("title", "???"), tex)
		stage.add_child(item)
		
		live_items.append(ItemState.new(item, now_ms))
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


func _on_image_request_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		push_error("Failed to fetch image list: " + str(response_code))
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		push_error("JSON parse failed: " + json.get_error_message())
		return

	var data: Dictionary = json.data
	if typeof(data) != TYPE_DICTIONARY or not data.has("items"):
		push_error("JSON response is fucky")
		return

	image_queue.clear()
	load_index = 0
	cycle_index = 0

	for image_info in data["items"]:
		image_queue.append({
			"title": image_info.get("title", "???"),
			"src": image_info.get("src", "")
			})
			
	_fetch_next_image()


func _fetch_next_image():
	if load_index >= image_queue.size():
		print("All images fetched.")
		return

	var info := image_queue[load_index]
	var full_url: String = "http://localhost:3030" + info["src"]
	image_fetcher.request(full_url)


func _on_image_fetcher_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		push_warning("Skipping image due to error code: " + str(response_code))
		_fetch_next_image()
		return

	print("Recieved image, code =", response_code, "bytes =", body.size())
	print("Image header:", body.slice(0, 8))

	var img := Image.new()
	var err := img.load_webp_from_buffer(body)
	if err != OK:
		push_warning("Failed to decode webp at index " + str(load_index))
		load_index += 1
		_fetch_next_image()
		return
		
	var tex := ImageTexture.create_from_image(img)
	image_queue[load_index]["texture"] = tex

	load_index += 1
	_fetch_next_image()


func create_image_item(title: String, texture: Texture2D = null) -> Panel:
	var box := Panel.new()
	box.name = title
	box.size = ITEM_SIZE
	box.custom_minimum_size = ITEM_SIZE

	# Make Panel visible
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.15, 0.15, 0.15, 0.85)
	box.add_theme_stylebox_override("panel", panel)

	var label := Label.new()
	label.name = "Label"
	label.text = "!" + title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_bottom = 0
	label.anchor_right = 1
	label.offset_top = 0
	label.offset_bottom = 48
	label.add_theme_color_override("font_color", Color(1, 0, 0))
	label.add_theme_font_size_override("font_size", 48)
	box.add_child(label)

	var sprite := TextureRect.new()
	sprite.name = "TextureRect"
	sprite.texture = texture
	sprite.anchor_left = 0
	sprite.anchor_top = 0
	sprite.anchor_bottom = 1
	sprite.anchor_right = 1
	sprite.offset_left = 0
	sprite.offset_top = 0
	sprite.offset_bottom = 0
	sprite.offset_right = 0
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(sprite)

	return box
