extends Node2D

@onready var columnA: VBoxContainer = $SubViewportContainer/SubViewport/ColumnA

const IMAGE_DIR: String = "res://images"
var scroll_speed: float = 100.0        ### pixels per second
var total_height: float = 0.0

func _ready() -> void:
	print("CodexOverlayMain ready to load images")

	load_images()

	### DUPLICATE TO LOOP SEAMLESSLY
	duplicate_column()

	### DELAY 1 FRAME TO CALCULATE LAYOUT SIZES
	await get_tree().process_frame

	total_height = columnA.get_combined_minimum_size().y
	print("Total combined column height:", total_height)

func _process(delta: float) -> void:
	columnA.position.y -= scroll_speed * delta
	columnA.position.y = wrapf(columnA.position.y, -total_height * 0.5, 0.0)

func load_images() -> void:
	var dir := DirAccess.open(IMAGE_DIR)
	if dir == null:
		push_warning("Image directory not found: " + IMAGE_DIR)
		return

	var files: Array[String] = []

	dir.list_dir_begin()
	var file_name := dir.get_next()

	### SCANS AND APPENDS .WEBP TO files ARRAY
	while file_name != "":
		if file_name.to_lower().ends_with(".webp"):
			files.append(file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

	### ALPHABETIZES files ARRAY
	files.sort()

	for image_title in files:
		var path: String = IMAGE_DIR + "/" + image_title
		print(" Loading WEBP image:", path)
		add_image(path)

	print("Finished loading images")

	### LOADS WEBP AS A 2D TEXTURE
func add_image(path: String) -> void:
	var texture := load(path) as Texture2D

	if texture == null:
		push_error("Failed to load texture: " + path)
		return

	### DERIVE TITLE FROM FILE NAME
	var title := path.get_file().get_basename().capitalize()

	### VBoxContainer TO HOLD LABEL + IMAGE
	var item_box := VBoxContainer.new()
	item_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_box.size_flags_vertical = Control.SIZE_FILL
	item_box.alignment = BoxContainer.ALIGNMENT_CENTER

	### LABEL NODE
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	### TextureRect FOR IMAGE
	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sprite.size_flags_vertical = Control.SIZE_FILL


	### ADD BOTH TO CONTAINER
	item_box.add_child(label)
	item_box.add_child(sprite)

	columnA.add_child(item_box)


	### POPULATE THE DUPLICATE COLUMN
func duplicate_column() -> void:
	var original_count := columnA.get_child_count()

	for i in range(original_count):
		var child := columnA.get_child(i)
		var dup := child.duplicate()
		columnA.add_child(dup)
