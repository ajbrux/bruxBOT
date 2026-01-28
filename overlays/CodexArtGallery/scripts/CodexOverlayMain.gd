extends Node2D

@onready var columnA: VBoxContainer = $SubViewportContainer/SubViewport/ColumnA

const IMAGE_DIR := "res://images"

func _ready() -> void:
	print("CodexOverlayMain ready")
	load_images()

func load_images() -> void:
	print(" Looking for images in:", IMAGE_DIR)

	var dir := DirAccess.open(IMAGE_DIR)
	if dir == null:
		push_warning(" Image directory not found: " + IMAGE_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".webp"):
			var path := IMAGE_DIR + "/" + file_name
			print(" Loading WEBP image:", path)
			add_image(path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print(" Finished loading images")

func add_image(path: String) -> void:
	var texture = load(path) as Texture2D
	if texture == null:
		push_error(" Failed to load texture: " + path)
		return

	var sprite := TextureRect.new()
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sprite.size_flags_vertical = Control.SIZE_FILL

	columnA.add_child(sprite)
