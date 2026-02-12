### ScrollingItem.gd
extends Panel
class_name ScrollingItem

var progress: float = 0.0
var elapsed_s: float = 0.0
var travel_time_s: float

var display_position: Vector2
var start_pos: Vector2
var off_pos: Vector2
var load_t: float
var focus_t: float
var focus_width_t: float
var focus_scale: float

var loaded := true
var focused := false

var label: Label
var disarmed_color: Color = Color.BLACK
var armed_color: Color = Color.GOLD

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
	
	if call_state == CallState.CALLING:
		call_timer += delta
		
		var target := display_position
		
		global_position = global_position.lerp(target - size * 0.5, 0.1)
		
		scale = scale.lerp(Vector2(512.0 / size.x, 512.0 / size.y), 0.1)
		
		if global_position.distance_to(target - size * 0.5) < 5:
			call_state = CallState.DISPLAYED
			call_timer = 0.0
			print(name, " DISPLAYED")
		
		return true
	
	if call_state == CallState.DISPLAYED:
		call_timer += delta
		if call_timer >= 3.0:
			call_state = CallState.RETURNING
			print(name, " RETURNING")
	
	if call_state == CallState.RETURNING:
		call_timer += delta
		
		var scroll_pos := start_pos.lerp(off_pos, progress)
		global_position = global_position.lerp(scroll_pos - size * 0.5, 0.1)
		scale = scale.lerp(Vector2.ONE, 0.1)
		
		if scale.distance_to(Vector2.ONE) < 0.1:
			call_state = CallState.NORMAL
			print(name, "RETURN COMPLETE")
		
		return true
	
	
	
	
	if progress >= 1.0:
		return false
	
	var p := start_pos.lerp(off_pos, progress)
	global_position = p - size * 0.5
	
	var in_focus: bool = abs(progress - focus_t) <= focus_width_t
	
	if in_focus and not focused:
		focused = true
		_arm()
	
	elif not in_focus and focused:
		focused = false
		_disarm()
	
	return true


func start_call(display_pos: Vector2) -> void:
	if call_state != CallState.NORMAL:
		return
	
	display_position = display_pos
	call_state = CallState.CALLING
	call_timer = 0.0
	print(name, " CALLED")
	


func _arm() -> void:
	if label:
		label.add_theme_color_override("font_color", armed_color)
		print(name, " ARMED at progress: ", progress)


func _disarm() -> void:
	if label:
		label.add_theme_color_override("font_color", disarmed_color)
		print(name, " DISARMED at progress: ", progress)
