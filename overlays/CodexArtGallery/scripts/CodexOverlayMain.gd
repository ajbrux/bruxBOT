extends Node2D

@onready var columnA: Control = $SubViewportContainer/SubViewport/ColumnA

@onready var http_request: HTTPRequest = $ImageRequest
@onready var image_fetcher: HTTPRequest = $ImageFetcher

var scroll_speed: float = 100.0        ### pixels per second
var total_height: float = 0.0
var current_image_index: int = 0

const VIEWPORT_HEIGHT := 1080
const LOAD_LINE := VIEWPORT_HEIGHT + 100   # where new images are spawned
const OFFLOAD_LINE := -200                 # when old images are removed or recycled
const ITEM_SPACING := 350                  # vertical spacing between items (label + image)

var visible_items: Array[Control] = []
var image_queue: Array[Dictionary] = []
var current_image_info: Dictionary

## temp debuc code
var load_index: int = 0
var cycle_index: int = 0


func _ready() -> void:
	print("CodexOverlayMain ready to load images")
	http_request.request("http://localhost:3030/overlay/images.json")

	await get_tree().process_frame
	total_height = columnA.get_combined_minimum_size().y
	print("Total combined column height:", total_height)

func _process(delta: float) -> void:

	if image_queue.is_empty() or load_index < image_queue.size():
		return

	for i in image_queue.size():
		if not image_queue[i].has("texture"):
			return  # still loading, wait

	# Scroll active items
	for item in visible_items:
		item.position.y -= scroll_speed * delta

	# Recycle offscreen items
	for item in visible_items:
		if item.position.y < OFFLOAD_LINE:
			recycle_item(item)
			break  # only do one per frame for smooth performance

	# Spawn new items at the bottom if needed
	if visible_items.is_empty() or get_lowest_item_y() < LOAD_LINE:
		spawn_next_item()

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
	# _add_item(title,texture)
	print("Added image: ", title)

	load_index += 1
	_fetch_next_image()


	# UI BUILDER FOR LABEL
func _add_item(title: String, texture: Texture2D) -> void:


	# VBoxContainer TO HOLD LABEL + IMAGE
	var item_box := VBoxContainer.new()
	item_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_box.size_flags_vertical = Control.SIZE_FILL
	item_box.alignment = BoxContainer.ALIGNMENT_CENTER

	# LABEL NODE
	var label := Label.new()
	label.text = "!" + title
	label.custom_minimum_size = Vector2(0, 175)       # columnA spacing managed with height value
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	# label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 90)

	# TextureRect FOR IMAGE
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.custom_minimum_size = Vector2(128, 128)
	sprite.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sprite.size_flags_vertical = Control.SIZE_FILL

	# POPULATE columnA WITH LABEL AND IMAGE
	item_box.add_child(label)
	item_box.add_child(sprite)
	columnA.add_child(item_box)

func spawn_next_item():
	if image_queue.is_empty():
		return

	var info = image_queue[cycle_index]
	cycle_index = (cycle_index + 1) % image_queue.size()

	var texture = info.get("texture", null)
	if texture == null:
		return

	var item = create_image_item(info["title"], texture)
	item.position.y = get_lowest_item_y() + ITEM_SPACING
	columnA.add_child(item)
	visible_items.append(item)

func recycle_item(item: Control):
	var info = image_queue[cycle_index]
	cycle_index = (cycle_index + 1) % image_queue.size()

	item.get_node("Label").text = "!" + info["title"]
	item.get_node("TextureRect").texture = info["texture"]
	item.position.y = get_lowest_item_y() + ITEM_SPACING

func create_image_item(title: String, texture: Texture2D) -> VBoxContainer:
	var item_box := VBoxContainer.new()
	item_box.name = "ImageItem"

	var label := Label.new()
	label.name = "Label"
	label.text = "!" + title
	label.custom_minimum_size = Vector2(0, 175)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_font_size_override("font_size", 90)

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
	
