### CodexOverlayMain.gd
extends Node2D

@onready var loader: ImageLoader = $ImageLoader
@onready var spawner: SpawnController = $SpawnController


func _ready() -> void:
	loader.images_ready.connect(_on_images_ready)
	loader.image_loaded.connect(_on_image_loaded)
	loader.all_images_loaded.connect(_on_all_images_loaded)
	
	print("READY: requesting images.json")
	loader.request_images("http://localhost:3030/overlay/images.json")


func _on_images_ready(queue: Array) -> void:
	spawner.set_queue(queue)
	print("Images metadata received: ", queue.size())


func _on_image_loaded(index: int, texture: Texture2D) -> void:
	spawner.on_image_loaded(index, texture)


func _on_all_images_loaded() -> void:
	print("All images fully loaded")
