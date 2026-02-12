### ScrollingItem.gd
extends Panel
class_name ScrollingItem

@export var call_travel_time: float = 0.6
@export var display_hold_time: float = 3.0

var progress: float = 0.0
var elapsed_s: float = 0.0
var travel_time_s: float

var call_start_position: Vector2
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
		
		var t: float = clamp(call_timer / call_travel_time, 0.0, 1.0)
		var eased := ease_in_out(t)
		
		global_position = call_start_position.lerp(display_position - size * 0.5, eased)
		
		var target_scale := Vector2(512.0 / size.x, 512.0 / size.y)
		scale = Vector2.ONE.lerp(target_scale, eased)
		
		if t >= 1.0:
			call_state = CallState.DISPLAYED
			call_timer = 0.0
			print(name, " DISPLAYED")
		
		return true
	
	if call_state == CallState.DISPLAYED:
		call_timer += delta
		if call_timer >= display_hold_time:
			call_state = CallState.RETURNING
			print(name, " RETURNING")
		
		return true
	
	if call_state == CallState.RETURNING:
		call_timer += delta
		
		var t: float = clamp(call_timer / call_travel_time, 0.0, 1.0)
		var eased := ease_in_out(t)
		
		var scroll_pos := start_pos.lerp(off_pos, progress) - size * 0.5
		var display_pos := display_position - size * 0.5
		
		global_position = display_pos.lerp(scroll_pos, eased)
		
		var target_scale := Vector2(512.0 / size.x, 512.0 / size.y)
		scale = target_scale.lerp(Vector2.ONE, eased)
		
		if t >= 1.0:
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
	call_start_position = global_position
	call_state = CallState.CALLING
	call_timer = 0.0
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
