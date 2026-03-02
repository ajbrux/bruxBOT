###res://scripts/CallAnimator.gd
class_name CallAnimator
extends RefCounted

enum State { IDLE, CALLING, DISPLAYED, RETURNING }

var state: State = State.IDLE
var call_progress: float = 0.0

var _timer: float = 0.0
var _travel_time: float = 1.0
var _hold_time: float = 0.0
var _wrapper: Control
var _fade_node: CanvasItem
var _cap: Dictionary
var _display_pos: Vector2 = Vector2.ZERO
var _return_start_gp: Vector2 = Vector2.ZERO


func begin_call(
	wrapper: Control,
	fade_node: CanvasItem,
	cap: Dictionary,
	display_pos: Vector2,
	travel_time: float,
	hold_time: float
) -> void:
	_wrapper = wrapper
	_fade_node = fade_node
	_cap = cap
	_display_pos = display_pos
	_travel_time = max(0.001, travel_time)
	_hold_time = max(0.0, hold_time)

	_timer = 0.0
	call_progress = 0.0
	state = State.CALLING


func update(delta: float) -> bool:
	# returns true while active, false when idle
	if state == State.IDLE:
		return false
	
	_timer += delta
	
	match state:
		State.CALLING:
			var t: float = clamp(_timer / _travel_time, 0.0, 1.0)
			update_calling(_wrapper, _fade_node, _cap, _display_pos, t)
			if t >= 1.0:
				state = State.DISPLAYED
				_timer = 0.0
			return true
	
		State.DISPLAYED:
			if _timer >= _hold_time:
				state = State.RETURNING
				_timer = 0.0
				_return_start_gp = _wrapper.global_position

		State.RETURNING:
			var t: float = clamp(_timer / _travel_time, 0.0, 1.0)
			update_returning(_wrapper, _fade_node, _cap, _return_start_gp, t)
			if t >= 1.0:
				CallAnimator.restore_to_original_parent(_wrapper, _cap)
				_wrapper.scale = Vector2.ONE
				
				if _fade_node != null:
					_fade_node.modulate.a = 1.0
				
				state = State.IDLE
				_timer = 0.0
				
				_wrapper = null
				_fade_node = null
				_cap = {}
				_display_pos = Vector2.ZERO
				_return_start_gp = Vector2.ZERO
	
	return true


#animations
func _ease_in_out(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


static func _scale_to_512(wrapper: Control) -> Vector2:
	# guard against div-by-zero if something is still 0 size
	var sx := wrapper.size.x
	var sy := wrapper.size.y
	if sx <= 0.001 or sy <= 0.001:
		return Vector2.ONE
	return Vector2(512.0 / sx, 512.0 / sy)

#instance helpers
static func _start_global(cap: Dictionary, fallback: Vector2) -> Vector2:
	return cap.get("start_global_position", fallback)


static func _return_target_global(cap: Dictionary, fallback: Vector2 ) -> Vector2:
	var parent: Node = cap.get("original_parent", null)
	var local: Vector2 = cap.get("original_local_position", fallback)

	var parent_ci := parent as CanvasItem
	if parent_ci == null:
		return local

	return parent_ci.get_global_transform_with_canvas() * local


#internals
func update_calling(
	wrapper: Control, 
	fade_node: CanvasItem,
	cap: Dictionary,
	display_pos: Vector2,
	t01: float
) -> void:
	var t: float = clamp(t01, 0.0, 1.0)
	call_progress = t
	
	var eased := _ease_in_out(t)
	
	var start_gp: Vector2 = _start_global(cap, wrapper.global_position)
	wrapper.global_position = start_gp.lerp(display_pos, eased)
	
	var target_scale: Vector2 = _scale_to_512(wrapper)
	wrapper.scale = Vector2.ONE.lerp(target_scale, eased)
	
	if fade_node != null:
		fade_node.modulate.a = 1.0 - eased


func update_returning(
	wrapper: Control,
	fade_node: CanvasItem,
	cap: Dictionary,
	return_start_gp: Vector2,
	t01: float
) -> void:
	var t: float = clamp(t01, 0.0, 1.0)
	call_progress = t

	var eased := _ease_in_out(t)

	var target_gp: Vector2 = _return_target_global(cap, wrapper.global_position)
	wrapper.global_position = return_start_gp.lerp(target_gp, eased)

	var display_scale := _scale_to_512(wrapper)
	wrapper.scale = display_scale.lerp(Vector2.ONE, eased)

	if fade_node != null:
		fade_node.modulate.a = eased


#re-parenting handlers
static func capture_reparent(node: Control) -> Dictionary:
	return {
		"original_parent": node.get_parent(),
		"original_index": node.get_index(),
		"original_local_position": node.position,
		"start_global_position": node.global_position
	}


static func preserve_world_position_across_reparent(node: Control, new_parent: Node) -> void:
	var gp: Vector2 = node.global_position
	var old_parent := node.get_parent()
	if old_parent:
		old_parent.remove_child(node)
	new_parent.add_child(node)
	node.global_position = gp


static func restore_to_original_parent(node: Control, cap: Dictionary) -> void:
	var parent: Node = cap.get("original_parent", null)
	if parent == null:
		return
	var idx: int = int(cap.get("original_index", 0))
	var local: Vector2 = cap.get("original_local_position", node.position)
	var cur_parent := node.get_parent()
	if cur_parent:
		cur_parent.remove_child(node)
	parent.add_child(node)
	parent.move_child(node, idx)
	node.position = local


#coordinate space handlers

#config

#call state machine
