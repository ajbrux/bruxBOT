### res://scripts/ScrollingItem.gd
extends Panel
class_name ScrollingItem

@export var call_travel_time: float = 2.5
@export var display_hold_time: float = 3.0

var call_anim := CallAnimator.new()

var progress: float = 0.0
var elapsed_s: float = 0.0
var travel_time_s: float

var call_start_position: Vector2
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
var disarmed_color: Color = Color.ORANGE_RED
var armed_color: Color = Color.DARK_ORANGE

var sprite_wrapper: Control
var call_progress: float
var display_layer: Control
var reparent_cap: Dictionary




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
	
	print("\n=== DEBUG ScrollingItem.setup ===", name)
	DebugCode.space(true, self, self, "ScrollingItem Panel")
	print("Panel modulate/self_modulate=", modulate, self_modulate)

	var sb = get_theme_stylebox("panel")
	print("theme_stylebox(panel)=", sb, " type=", sb.get_class() if sb else "null")


func update_item(delta: float, speed_multiplier: float) -> bool:
	
	
	if not loaded:
		pass
	# one-time “first frame visible” log
	if loaded and progress > 0.0 and progress < 0.02:
		print("[item first move] ", name, " panel alpha mod/self=",
			modulate.a, self_modulate.a,
			" sprite_wrapper alpha=", sprite_wrapper.modulate.a if sprite_wrapper else -1.0)

	
	
	
	progress += (delta / travel_time_s) * speed_multiplier
	var p := start_pos.lerp(off_pos, progress)
	global_position = p - size * 0.5
	
	if call_anim.update(delta):
		call_progress = call_anim.call_progress
		if call_anim.state == CallAnimator.State.IDLE:
			print(name, " RETURN COMPLETE")
	else:
		call_progress = 0.0
	
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
	if call_anim.state != CallAnimator.State.IDLE:
		return
	
	display_layer = p_display_layer
	
	reparent_cap = CallAnimator.capture_reparent(sprite_wrapper)
	CallAnimator.preserve_world_position_across_reparent(sprite_wrapper, display_layer)
	
	call_anim.begin_call(
		sprite_wrapper,
		label,
		reparent_cap,
		display_pos,
		call_travel_time,
		display_hold_time
	)
	
	print(name, " CALLED")





func _arm() -> void:
	if label:
		label.add_theme_color_override("font_color", armed_color)
		print(name, " ARMED at progress: ", progress)


func _disarm() -> void:
	if label:
		label.add_theme_color_override("font_color", disarmed_color)
		print(name, " DISARMED at progress: ", progress)
