### res://scripts/ImageLoader.gd
extends Node
class_name ImageLoader

@onready var http_request: HTTPRequest = $ImageRequest
@onready var image_fetcher: HTTPRequest = $ImageFetcher

var queue: Array[Dictionary] = []
var load_index: int = 0

signal images_ready(queue: Array)
signal image_loaded(index: int, texture: Texture2D)
signal all_images_loaded()


func _ready() -> void:
	http_request.request_completed.connect(_on_ImageRequest_request_completed)
	image_fetcher.request_completed.connect(_on_ImageFetcher_request_completed)


func request_images(url: String) -> void:
	http_request.request(url)


func _on_ImageRequest_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		push_error("Failed to fetch image list: %s" % response_code)
		return

	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		push_error("JSON parse failed")
		return

	if typeof(json.data) != TYPE_DICTIONARY or not json.data.has("items"):
		push_error("Invalid JSON format")
		return

	queue.clear()
	load_index = 0

	for item in json.data["items"]:
		queue.append({
			"title": item.get("title", "???"),
			"src": item.get("src", "")
		})

	emit_signal("images_ready", queue.duplicate())
	_fetch_next_image()


func _fetch_next_image() -> void:
	if load_index >= queue.size():
		emit_signal("all_images_loaded")
		return

	var url: String = "http://localhost:3030" + queue[load_index]["src"]
	image_fetcher.request(url)


func _on_ImageFetcher_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		push_warning("Skipping image at index %d" % load_index)
		load_index += 1
		_fetch_next_image()
		return

	var img := Image.new()
	if img.load_webp_from_buffer(body) != OK:
		push_warning("Failed to decode image at index %d" % load_index)
		load_index += 1
		_fetch_next_image()
		return

	var tex := ImageTexture.create_from_image(img)
	queue[load_index]["texture"] = tex
	emit_signal("image_loaded", load_index, tex)

	load_index += 1
	_fetch_next_image()
