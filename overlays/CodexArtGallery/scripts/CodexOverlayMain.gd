extends Node2D

@onready var columnA: VBoxContainer = $SubViewportContainer/SubViewport/ColumnA

### .json SOURCE // HTML
@onready var http_request: HTTPRequest = $ImageRequest
@onready var image_fetcher: HTTPRequest = $ImageFetcher
###

### LOCAL SOURCE // GODOT ENGINE
# const IMAGE_DIR: String = "res://images"
###

var scroll_speed: float = 100.0        ### pixels per second
var total_height: float = 0.0
var current_image_index: int = 0

var image_queue: Array[Dictionary] = []
var current_image_info: Dictionary


func _ready() -> void:
	print("CodexOverlayMain ready to load images")

	## temp debug code ##
	$ImageRequest.request_completed.connect(func(result, response_code, headers, body):
		print("DEBUG: ImageRequest request_completed signal fired (inline connect)")
		print("DEBUG: response code =", response_code)
	)
	##

### .json SOURCE // HTML
	http_request.request("http://localhost:3030/overlay/images.json")
###

### LOCAL SOURCE // GODOT ENGINE
#    load_images()
#
#    # DUPLICATE TO LOOP SEAMLESSLY
#    duplicate_column()
###

	# DELAY 1 FRAME TO CALCULATE LAYOUT SIZES
	await get_tree().process_frame
	total_height = columnA.get_combined_minimum_size().y
	print("Total combined column height:", total_height)

func _process(delta: float) -> void:
	columnA.position.y -= scroll_speed * delta
	columnA.position.y = wrapf(columnA.position.y, -total_height * 0.5, 0.0)

## bad logic ##
#func load_images() -> void:
#    var url := "http://localhost:3030/overlay/images.json"
#    http_request.request(url)
##

	# .json METADATA LOADED FROM node.js
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
	if current_image_index >= image_queue.size():
		print("All images fetched.")
		return

	current_image_info = image_queue[current_image_index]
	current_image_index += 1

	var title = current_image_info["title"]
	var src = current_image_info["src"]
	var full_url = "http://localhost:3030" + src
	# print("fetching image:", full_url)
	image_fetcher.request(full_url)

	# IMAGE BINARY LOADER
func _on_image_fetcher_request_completed(result, response_code, _headers, body):
	print("Recieved image, code =", response_code, "bytes =", body.size())

	if response_code != 200:
		push_warning("Skipping image due to error code: " + str(response_code))
		current_image_index += 1
		_fetch_next_image()
		return

	print("Image header:", body.slice(0, 8))

	## temp code ##
	var img_test := Image.create(128, 128, false, Image.FORMAT_RGB8)
	img_test.fill(Color.RED)
	var tex := ImageTexture.create_from_image(img_test)
	_add_item("INLINE TEST", tex)
	##

	var img := Image.new()
	var err := img.load_webp_from_buffer(body)
	print("webp decode status of image size", body.size(), ":", err)
	if err != OK:
		push_warning("Image decode failed: " + str(err))
		return

	var texture := ImageTexture.create_from_image(img)
	var title: String = current_image_info["title"]
	print("Loaded image for: ", title)
	_add_item(title,texture)
	print("Added image: ", title)
	current_image_index += 1
	_fetch_next_image()


	# UI BUILDER FOR LABEL
func _add_item(title: String, texture: Texture2D) -> void:

## bad logic ##
#func add_remote_image(title: String, url: String) -> void:
#    var texture := ImageTexture.new()
#    var img := Image.new()
#    var img_data := Image.load_from_file(url) # INVALID in browser export!
##

### LOCAL SOURCE // GODOT ENGINE
#func load_images() -> void:
#    var dir := DirAccess.open(IMAGE_DIR)
#    if dir == null:
#        push_warning("Image directory not found: " + IMAGE_DIR)
#        return
#
#    var files: Array[String] = []
#
#    dir.list_dir_begin()
#    var file_name := dir.get_next()
#
#    # SCANS AND APPENDS .WEBP TO files ARRAY
#    while file_name != "":
#        if file_name.to_lower().ends_with(".webp"):
#            files.append(file_name)
#        file_name = dir.get_next()
#
#    dir.list_dir_end()
#
#    ### ALPHABETIZES files ARRAY
#    files.sort()
#
#    for image_title in files:
#        var path: String = IMAGE_DIR + "/" + image_title
#        print(" Loading WEBP image:", path)
#        add_image(path)
#
#    print("Finished loading images")
#
#    # UI BUILDER FOR LABEL
#func add_image(path: String) -> void:
#    var texture := load(path) as Texture2D
#
#    if texture == null:
#        push_error("Failed to load texture: " + path)
#        return
#
#    # DERIVE TITLE FROM FILE NAME
#    var title := "!" + path.get_file().get_basename()

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


#    # POPULATE THE DUPLICATE COLUMN
#func duplicate_column() -> void:
#    var original_count := columnA.get_child_count()
#
#    for i in range(original_count):
#        var child := columnA.get_child(i)
#        var dup := child.duplicate()
#        columnA.add_child(dup)
