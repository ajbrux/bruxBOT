### res://scripts/DebugCode.gd
class_name DebugCode
extends RefCounted

static func _owner_label(owner: Object) -> String:
	if owner == null:
		return "<null>"
	if owner is Node:
		return "%s(%s)" % [(owner as Node).name, owner.get_class()]
	return "%s(%s)" % [str(owner), owner.get_class()]


static func stack(enabled: bool, owner: Object, tag: String) -> void:
	if not enabled:
		return
	print("\n=== STACK:", _owner_label(owner), ":", tag, "===")
	print_stack()


static func chain(enabled: bool, owner: Object, n: Node, tag: String) -> void:
	if not enabled:
		return
	if n == null:
		print("\n=== PARENT CHAIN:", _owner_label(owner), ":", tag, "=== (n is null)")
		return
	print("\n=== PARENT CHAIN:", _owner_label(owner), ":", tag, "===")
	var cur: Node = n
	while cur != null:
		var p := cur.get_parent()
		print("%s (%s)  path=%s  parent=%s" % [
			cur.name, cur.get_class(), str(cur.get_path()),
			p.name if p else "NONE"
		])
		cur = p


static func subtree(enabled: bool, owner: Object, root: Node, tag: String, max_depth: int = 6) -> void:
	if not enabled:
		return
	print("\n=== SUBTREE:", _owner_label(owner), ":", tag, " root=", root.get_path(), "===")
	_print_tree_limited(root, 0, max_depth)


static func _print_tree_limited(n: Node, depth: int, max_depth: int) -> void:
	var indent := "  ".repeat(depth)
	print("%s- %s (%s)" % [indent, n.name, n.get_class()])
	if depth >= max_depth:
		return
	for c in n.get_children():
		_print_tree_limited(c, depth + 1, max_depth)


static func space(enabled: bool, owner: Object, ci: CanvasItem, tag: String) -> void:
	if not enabled:
		return
	print("\n=== SPACE:", _owner_label(owner), ":", tag, "===")
	print("node:", ci.name, " class:", ci.get_class(), " path:", ci.get_path())
	print(" local pos:", ci.position, " global pos:", ci.global_position)
	print(" global xform:", ci.get_global_transform())
	print(" canvas xform:", ci.get_global_transform_with_canvas())
