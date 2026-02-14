### res://scripts/ScrollingItem.gd
extends Panel
class_name ScrollingItem

@export var call_travel_time: float = 2.5
@export var display_hold_time: float = 3.0

var call_progress: float = 0.0
var progress: float = 0.0
var elapsed_s: float = 0.0
var travel_time_s: float

var call_start_position: Vector2
var display_position: Vector2
# var return_target_position: Vector2
var start_pos: Vector2
var off_pos: Vector2
var load_t: float
var focus_t: float
var focus_width_t: float
var focus_scale: float
var sprite: TextureRect
var blurb_label: Label		#saving for later

var loaded := true
var focused := false

var label: Label
var disarmed_color: Color = Color.BLACK
var armed_color: Color = Color.GOLD

var original_local_position: Vector2
var return_start_position: Vector2
var display_layer: Control
var sprite_wrapper: Control
var original_parent: Node
var original_index: int

enum CallState {
	NORMAL,
	CALLING,
	DISPLAYED,
	RETURNING
}

var call_state: CallState = CallState.NORMAL
var call_timer: float = 0.0


func setup(
	p_travel_time_s: float,
	p_start_pos: Vector2,
	p_off_pos: Vector2,
	p_load_t: float,
	p_focus_t: float,
	p_focus_width_t: float,
	p_focus_scale: float
) -> void:
	travel_time_s = p_travel_time_s
	start_pos = p_start_pos
	off_pos = p_off_pos
	load_t = p_load_t
	focus_t = p_focus_t
	focus_width_t = p_focus_width_t
	focus_scale = p_focus_scale

	global_position = start_pos - size * 0.5
	visible = true


func update_item(delta: float, speed_multiplier: float) -> bool:
	progress += (delta / travel_time_s) * speed_multiplier
	
	var p := start_pos.lerp(off_pos, progress)
	global_position = p - size * 0.5
	
	if call_state == CallState.CALLING:
		call_timer += delta
		
		var t: float = clamp(call_timer / call_travel_time, 0.0, 1.0)
		call_progress = t
		var eased := ease_in_out(t)
		
		var target := display_position
		
		sprite_wrapper.global_position = call_start_position.lerp(target, eased)
		
		var target_scale := Vector2(512.0 / sprite_wrapper.size.x, 512.0 / sprite_wrapper.size.y)
		sprite_wrapper.scale = Vector2.ONE.lerp(target_scale, eased)
		
		label.modulate.a = 1.0 - eased
		
		if t >= 1.0:
			call_state = CallState.DISPLAYED
			call_timer = 0.0
			print(name, " DISPLAYED")
		
		return true
	
	if call_state == CallState.DISPLAYED:
		call_timer += delta
		
		if call_timer >= display_hold_time:
			call_state = CallState.RETURNING
			call_timer = 0.0
			return_start_position = sprite_wrapper.global_position
			print(name, " RETURNING")
		
		return true
	
	if call_state == CallState.RETURNING:
		call_timer += delta
		
		var t: float = clamp(call_timer / call_travel_time, 0.0, 1.0)
		var eased := ease_in_out(t)
		
		var target := (original_parent as CanvasItem).get_global_transform_with_canvas() * original_local_position
		
		sprite_wrapper.global_position = return_start_position.lerp(target, eased)
		
		var display_scale := Vector2(512.0 / sprite_wrapper.size.x, 512.0 / sprite_wrapper.size.y)
		sprite_wrapper.scale = display_scale.lerp(Vector2.ONE, eased)
		
		label.modulate.a = eased
		
		if t >= 1.0:
			var gp := sprite_wrapper.global_position
			
			display_layer.remove_child(sprite_wrapper)
			original_parent.add_child(sprite_wrapper)
			original_parent.move_child(sprite_wrapper, original_index)
			
			sprite_wrapper.position = original_local_position
			sprite_wrapper.scale = Vector2.ONE
			
			label.modulate.a = 1.0
			
			call_state = CallState.NORMAL
			print(name, "RETURN COMPLETE")
		
		return true
	
	if progress >= 1.0:
		return false
	
	var in_focus: bool = abs(progress - focus_t) <= focus_width_t
	
	if in_focus and not focused:
		focused = true
		_arm()
	
	elif not in_focus and focused:
		focused = false
		_disarm()
	
	return true


func start_call(display_pos: Vector2, p_display_layer: Control) -> void:
	if call_state != CallState.NORMAL:
		return
	
	
	
	dbg_stack("start_call ENTER")
	dbg_chain(sprite_wrapper, "BEFORE reparent")
	dbg_space(sprite_wrapper, "BEFORE reparent")
	
	
	
	display_layer = p_display_layer
	display_position = display_pos
	
	original_parent = sprite_wrapper.get_parent()
	original_index = sprite_wrapper.get_index()
	
	original_local_position = sprite_wrapper.position
	call_start_position = sprite_wrapper.global_position
	
	original_parent.remove_child(sprite_wrapper)
	display_layer.add_child(sprite_wrapper)
	
	#preserve world position
	sprite_wrapper.global_position = call_start_position
	
	
	
	dbg_stack("start_call ENTER")
	dbg_chain(sprite_wrapper, "AFTER reparent")
	dbg_space(sprite_wrapper, "AFTER reparent")
	
	
	
	call_state = CallState.CALLING
	call_timer = 0.0
	call_progress = 0.0
	
	print(name, " CALLED")


func ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _arm() -> void:
	if label:
		label.add_theme_color_override("font_color", armed_color)
		print(name, " ARMED at progress: ", progress)


func _disarm() -> void:
	if label:
		label.add_theme_color_override("font_color", disarmed_color)
		print(name, " DISARMED at progress: ", progress)











@export var debug_calls := true

func dbg_stack(tag: String) -> void:
	if not debug_calls:
		return
	print("\n=== STACK:", name, ":", tag, "===")
	print_stack()

func dbg_chain(n: Node, tag: String) -> void:
	if not debug_calls:
		return
	print("\n=== PARENT CHAIN:", name, ":", tag, "===")
	var cur: Node = n
	while cur:
		var p := cur.get_parent()
		print("%s (%s)  path=%s  parent=%s" % [
			str(cur.name), cur.get_class(), str(cur.get_path()),
			str(p.name) if p else "NONE"
		])
		cur = p


func dbg_subtree(root: Node, tag: String, max_depth: int = 6) -> void:
	if not debug_calls:
		return
	print("\n=== SUBTREE:", name, ":", tag, " root=", root.get_path(), "===")
	_print_tree_limited(root, 0, max_depth)

func _print_tree_limited(n: Node, depth: int, max_depth: int) -> void:
	var indent := "  ".repeat(depth)
	print("%s- %s (%s)" % [indent, n.name, n.get_class()])
	if depth >= max_depth:
		return
	for c in n.get_children():
		_print_tree_limited(c, depth + 1, max_depth)


func dbg_space(ci: CanvasItem, tag: String) -> void:
	if not debug_calls:
		return
	print("\n=== SPACE:", name, ":", tag, "===")
	print("node:", ci.name, " class:", ci.get_class(), " path:", ci.get_path())
	print(" local pos:", ci.position, " global pos:", ci.global_position)
	print(" global xform:", ci.get_global_transform())
	print(" canvas xform:", ci.get_global_transform_with_canvas())
