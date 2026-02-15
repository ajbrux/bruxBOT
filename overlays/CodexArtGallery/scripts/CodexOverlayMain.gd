### res://scripts/CodexOverlayMain.gd
extends Node2D

@onready var loader: ImageLoader = $ImageLoader
@onready var spawner: SpawnController = $SpawnController

var ws := WebSocketPeer.new()


const DBG_INIT := true
var _dbg_frames_left := 180 # ~3 seconds @ 60fps



func _ready() -> void:
	print("\n==============================")
	print("BOOT CodexOverlayMain _ready()")
	print("BUILD STAMP: 2026-02-13 A (init spam)")
	print("==============================\n")
	
	print("\n==============================")
	print("BOOT CodexOverlayMain _ready()")
	print("BUILD STAMP: 2026-02-13 A (init spam)")
	print("==============================\n")

	# Viewport + clear color
	var vp := get_viewport()
	vp.transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	
	DebugCode.kv(DBG_INIT, self, "viewport flags", {
		"viewport.transparent_bg": vp.transparent_bg,
		"viewport.size": vp.size,
		"content_scale": vp.content_scale_factor,
		"screen": DisplayServer.screen_get_size(),
		"window": DisplayServer.window_get_size(),
		"os": OS.get_name(),
		"platform": OS.get_distribution_name() if OS.has_method("get_distribution_name") else "<n/a>",
	})

	# Dump anything likely to paint a solid rect
	_dump_suspects(get_tree().current_scene)
	
	
	var err = ws.connect_to_url("ws://localhost:3030")
	if err != OK:
		print("WebSocket connection failed")
	
	loader.images_ready.connect(_on_images_ready)
	loader.image_loaded.connect(_on_image_loaded)
	loader.all_images_loaded.connect(_on_all_images_loaded)
	
	print("READY: requesting images.json")
	loader.request_images("http://localhost:3030/overlay/images.json")


func _process(_delta):
	# First few seconds: show heartbeat + WS state
	if DBG_INIT and _dbg_frames_left > 0:
		_dbg_frames_left -= 1
		if _dbg_frames_left % 30 == 0:
			print("[frame spam] dt=", _delta, " ws_state=", ws.get_ready_state(), " live_items=", spawner.live_items.size() if spawner else -1)
	ws.poll()
	
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count() > 0:
			var packet = ws.get_packet()
			var text = packet.get_string_from_utf8()
			_handle_ws_message(text)


func _handle_ws_message(text: String) -> void:
	
	if DBG_INIT:
		print("[ws msg] raw=", text)
	
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
	print("Images metadata received: ", queue.size())
	if DBG_INIT and queue.size() > 0:
		print("[images_ready] first item=", queue[0])
	spawner.set_queue(queue)
	print("Images metadata received: ", queue.size())


func _on_image_loaded(index: int, texture: Texture2D) -> void:
	print("[image_loaded] idx=", index, " tex=", texture, " size=", texture.get_size() if texture else Vector2.ZERO)
	spawner.on_image_loaded(index, texture)


func _on_all_images_loaded() -> void:
	print("All images fully loaded")








func _dump_suspects(root: Node) -> void:
	print("\n=== DEBUG suspect scan ===")
	_scan_node(root)
	print("=== END suspect scan ===\n")


func _scan_node(n: Node) -> void:
	# Things that often “paint the screen”
	if n is ColorRect or n is Panel:
		print("SUSPECT:", n.get_path(), " class=", n.get_class())

	# Also: any CanvasItem with alpha=1 and visible can still hide issues
	if n is CanvasItem:
		var ci := n as CanvasItem
		if ci.visible:
			# low-noise: only print if fully opaque modulates (common culprit)
			if ci.modulate.a >= 0.99 or ci.self_modulate.a >= 0.99:
				pass

	for c in n.get_children():
		_scan_node(c)
