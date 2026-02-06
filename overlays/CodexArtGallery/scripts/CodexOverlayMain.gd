extends Node2D

@onready var columnA: Control = $SubViewportContainer/SubViewport/ColumnA
@onready var http_request: HTTPRequest = $ImageRequest
@onready var image_fetcher: HTTPRequest = $ImageFetcher

var scroll_speed: float = 225.0        ### pixels per second
var total_height: float = 0.0

const VIEWPORT_HEIGHT := 1080
const ITEM_HEIGHT := 400
const START_NODE := VIEWPORT_HEIGHT + (ITEM_HEIGHT * 2)   # where new images are spawned
const FILL_NODE := VIEWPORT_HEIGHT + ITEM_HEIGHT
const OFFLOAD_LINE := -512                 # when old images are removed or recycled
const ITEM_SPACING := 400                  # vertical spacing between items (label + image)
const TRIGGER_ON := 540   # middle of viewport
const TRIGGER_OFF := 200  # higher zone to deactivate

var active_callables: Array[String] = []
var visible_items: Array[Control] = []
var image_queue: Array[Dictionary] = []
var current_image_info: Dictionary

	# COUNTERS/TRACKERS
var load_index: int = 0
var cycle_index: int = 0
var current_image_index: int = 0
var recycle_index: int = 0
var is_paused: bool = false
var focused_item: Control = null


func _ready() -> void:
	print("CodexOverlayMain READY TO LOAD images.json")
	http_request.request("http://localhost:3030/overlay/images.json")

	await get_tree().process_frame
	total_height = columnA.get_combined_minimum_size().y
	print("Total combined column height:", total_height)


func _process(delta: float) -> void:
	if is_paused:
		return

	# Callable zone activation
	for item in visible_items:
		var y = item.global_position.y
		var label = item.get_node("Label")
		var title = _label_to_title(label.text)

		if y < TRIGGER_OFF:
			if active_callables.has(title):
				active_callables.erase(title)
				print("Deactivated:", title)

		if y < TRIGGER_ON:
			active_callables.append(title)
			print("Activated:", title)

	# Scroll active items
	for item in visible_items:
		item.position.y -= scroll_speed * delta

	# Recycle offscreen items
	for item in visible_items:
		if item.position.y < OFFLOAD_LINE:
			recycle_item(item)
			break

	# Fill texture
	for item in visible_items:
		if not item.has_meta("filled") and item.position.y < FILL_NODE:
			populate_texture(item)

	# Spawn new items at the bottom
	if visible_items.is_empty() or get_lowest_item_y() < START_NODE:
		spawn_next_item()


func _focus_item(item: Control):
	is_paused = true
	focused_item = item

	var tween := create_tween()
	tween.tween_property(item, "scale", Vector2(1.5, 1.5), 0.3).set_trans(Tween.TRANS_CUBIC)

	# Show a label or RichTextLabel overlay with the image blurb here
	# show_blurb_for(item)

	await get_tree().create_timer(2.0).timeout

	# hide_blurb()
	tween = create_tween()
	tween.tween_property(item, "scale", Vector2(1, 1), 0.3)

	await tween.finished
	is_paused = false
	focused_item = null


func trigger_focus(title: String) -> void:
	for item in visible_items:
		var label = item.get_node("Label")
		var item_title := _label_to_title(label.text)

		if item_title == title:
			_focus_item(item)
			break


func _on_image_request_request_completed(result, response_code, headers, body):
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

	for image_info in data["items"]:
		var title = image_info.get("title", "???")
		var src = image_info.get("src", "")
		print("Queuing image: ", src)
		image_queue.append({"title": title, "src": src})
		var full_url = "http://localhost:3030" + src
		print("Fetching image: " + full_url)
	_fetch_next_image()


func _fetch_next_image():
	if load_index >= image_queue.size():
		print("All images fetched.")
		return

	current_image_info = image_queue[load_index]

	# current_image_index += 1

	# var title = current_image_info["title"]
	var src = current_image_info["src"]
	var full_url = "http://localhost:3030" + src
	print("fetching image:", full_url)
	image_fetcher.request(full_url)


	# IMAGE BINARY LOADER
func _on_image_fetcher_request_completed(result, response_code, _headers, body):
	print("Recieved image, code =", response_code, "bytes =", body.size())

	if response_code != 200:
		push_warning("Skipping image due to error code: " + str(response_code))
		# current_image_index += 1
		_fetch_next_image()
		return

	print("Image header:", body.slice(0, 8))

	var img := Image.new()
	var err := img.load_webp_from_buffer(body)
	print("webp decode status of image size", body.size(), ":", err)
	if err != OK:
		push_warning("Image decode failed: " + str(err))
		return

	var texture := ImageTexture.create_from_image(img)
	# current_image_info["texture"] = texture
	image_queue[load_index]["texture"] = texture
	var title: String = current_image_info["title"]
	print("Loaded image for: ", title)
	print("Loaded texture for : ", title)

	load_index += 1
	_fetch_next_image()


func spawn_next_item():
	if image_queue.is_empty():
		return

	var info = image_queue[cycle_index]
	cycle_index = (cycle_index + 1) % image_queue.size()

	var texture = info.get("texture", null)
	var is_empty := texture == null
	if is_empty:
		return

	var item = create_image_item(info["title"], texture)
	item.position.y = get_lowest_item_y() + ITEM_HEIGHT
	item.set_meta("filled", not is_empty)
	item.set_meta("title", info["title"])

	columnA.add_child(item)
	visible_items.append(item)


func populate_texture(item: Control):
	var label = item.get_node("Label")
	var title = _label_to_title(label.text)

	for info in image_queue:
		if info["title"] == title and info.has("texture"):
			item.get_node("TextureRect").texture = info ["texture"]
			item.set_meta("filled", true)
			print("Populated texture for: ", title)
			break


func recycle_item(item: Control):
	var info = image_queue[recycle_index]
	recycle_index = (recycle_index + 1) % image_queue.size()

	# Guarantee that the item has only 2 children
	for child in item.get_children():
		item.remove_child(child)
		child.queue_free()

	# Recreate label and texture
	var label := Label.new()
	label.name = "Label"
	label.text = "!" + info["title"]
	label.custom_minimum_size = Vector2(0, 175)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 70)

	# Recreate image
	var sprite := TextureRect.new()
	sprite.name = "TextureRect"
	sprite.texture = info["texture"]
	sprite.custom_minimum_size = Vector2(128, 128)
	sprite.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Add to the item
	item.add_child(label)
	item.add_child(sprite)

	# Reposition and tag
	item.position.y = get_lowest_item_y() + ITEM_SPACING
	item.set_meta("title", info["title"])
	item.set_meta("filled", true)
	
	print("Visible items count:", visible_items.size())


func create_image_item(title: String, texture: Texture2D = null) -> VBoxContainer:
	var item_box := VBoxContainer.new()
	item_box.name = "ImageItem"

	var label := Label.new()
	label.name = "Label"
	label.text = "!" + title
	label.custom_minimum_size = Vector2(0, 175)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_font_size_override("font_size", 70)

	var sprite := TextureRect.new()
	sprite.name = "TextureRect"
	sprite.texture = texture
	sprite.custom_minimum_size = Vector2(128, 128)
	sprite.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	item_box.add_child(label)
	item_box.add_child(sprite)
	return item_box


func get_lowest_item_y() -> float:
	if visible_items.is_empty():
		return 0.0
	var last := visible_items[-1]
	return last.position.y


func _label_to_title(text: String) -> String:
	if text.begins_with("!"):
		return text.substr(1)
	return text
