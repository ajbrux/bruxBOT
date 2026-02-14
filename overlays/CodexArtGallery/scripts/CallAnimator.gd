###res://scripts/CallAnimator.gd
class_name CallAnimator
extends RefCounted

class ReparentCapture:
	var original_parent: Node
	var original_index: int
	var original_local_position: Vector2
	var start_global_position: Vector2

#config


#wiring


#outputs


#internals


#animations


#call state machine


#re-parenting
static func capture_reparent(node: Control) -> Dictionary:
	return {
		"original_parent": node.get_parent(),
		"original_index": node.get_index(),
		"original_local_position": node.position,
		"start_global_position": node.global_position
	}


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
static func preserve_world_position_across_reparent(node: Control, new_parent: Node) -> void:
	var gp: Vector2 = node.global_position
	
	var old_parent := node.get_parent()
	if old_parent:
		old_parent.remove_child(node)
	new_parent.add_child(node)
	node.global_position = gp


static func compute_return_target_global(cap: Dictionary) -> Vector2:
	var parent: Node = cap.get("original_parent", null)
	var local: Vector2 = cap.get("original_local_position", Vector2.ZERO)
	
	var parent_ci := parent as CanvasItem
	if parent_ci == null:
		return local
	return parent_ci.get_global_transform_with_canvas() * local
