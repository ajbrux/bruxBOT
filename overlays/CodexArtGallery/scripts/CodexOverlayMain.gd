### res://scripts/CodexOverlayMain.gd
extends Node2D

@onready var loader: ImageLoader = $ImageLoader
@onready var spawner: SpawnController = $SpawnController

var ws := WebSocketPeer.new()


func _ready() -> void:
	var err = ws.connect_to_url("ws://localhost:3030")
	if err != OK:
		print("WebSocket connection failed")
	
	loader.images_ready.connect(_on_images_ready)
	loader.image_loaded.connect(_on_image_loaded)
	loader.all_images_loaded.connect(_on_all_images_loaded)
	
	print("READY: requesting images.json")
	loader.request_images("http://localhost:3030/overlay/images.json")


func _process(_delta):
	ws.poll()
	
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count() > 0:
			var packet = ws.get_packet()
			var text = packet.get_string_from_utf8()
			_handle_ws_message(text)


func _handle_ws_message(text: String) -> void:
	var json = JSON.new()
	if json.parse(text) != OK:
		return
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	if data.get("type") == "image_call":
		var title = String(data.get("title", "")).to_upper()
		print("WS image_call: ", title)
		spawner.start_call_by_title(title)


func _on_images_ready(queue: Array) -> void:
	spawner.set_queue(queue)
	print("Images metadata received: ", queue.size())


func _on_image_loaded(index: int, texture: Texture2D) -> void:
	spawner.on_image_loaded(index, texture)


func _on_all_images_loaded() -> void:
	print("All images fully loaded")
