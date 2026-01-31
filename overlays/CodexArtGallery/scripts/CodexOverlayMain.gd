extends Node2D

@onready var columnA: VBoxContainer = $SubViewportContainer/SubViewport/ColumnA

const IMAGE_DIR: String = "res://images"
var scroll_speed: float = 100.0        ### pixels per second
var total_height: float = 0.0

func _ready() -> void:
	print("CodexOverlayMain ready to load images")

	load_images()

	### Duplicate to loop seamlessly
	duplicate_column()

	### delay 1 frame to calculate layout sizes
	await get_tree().process_frame

	total_height = columnA.get_combined_minimum_size().y
	print("Total combined column height:", total_height)

func _process(delta: float) -> void:
	columnA.position.y -= scroll_speed * delta
	columnA.position.y = fmod(columnA.position.y, -total_height * 0.5)

func load_images() -> void:
	var dir := DirAccess.open(IMAGE_DIR)
	if dir == null:
		push_warning("Image directory not found: " + IMAGE_DIR)
		return

	var files: Array[String] = []

	dir.list_dir_begin()
	var file_name := dir.get_next()

	### scans and appends .webp to files Array
	while file_name != "":
		if file_name.to_lower().ends_with(".webp"):
			files.append(file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

	### alphabetizes files Array
	files.sort()

	for image_title in files:
		var path: String = IMAGE_DIR + "/" + image_title
		print(" Loading WEBP image:", path)
		add_image(path)

	print("Finished loading images")

	### loads webp as a 2D texture
func add_image(path: String) -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		push_error("Failed to load texture: " + path)
		return

	# Derive title from file name
	var title := path.get_file().get_basename().capitalize()

	# VBoxContainer to hold label + image
	var item_box := VBoxContainer.new()
	item_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_box.size_flags_vertical = Control.SIZE_FILL
	item_box.alignment = BoxContainer.ALIGNMENT_CENTER

	# Label node
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# TextureRect for image
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sprite.size_flags_vertical = Control.SIZE_FILL

	# Add both to container
	item_box.add_child(label)
	item_box.add_child(sprite)

	columnA.add_child(item_box)


	### populate the duplicate column
func duplicate_column() -> void:
	var original_count := columnA.get_child_count()

	for i in range(original_count):
		var child := columnA.get_child(i)
		var dup := child.duplicate()
		columnA.add_child(dup)
