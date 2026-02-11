### ScrollingItem.gd
extends Panel
class_name ScrollingItem


var spawn_ms: int
var travel_time_s: float

var start_pos: Vector2
var off_pos: Vector2
var load_t: float
var focus_t: float
var focus_width_t: float
var focus_scale: float

var loaded := true
var focused := false


func setup(
	p_spawn_ms: int,
	p_travel_time_s: float,
	p_start_pos: Vector2,
	p_off_pos: Vector2,
	p_load_t: float,
	p_focus_t: float,
	p_focus_width_t: float,
	p_focus_scale: float
) -> void:
	spawn_ms = p_spawn_ms
	travel_time_s = p_travel_time_s
	start_pos = p_start_pos
	off_pos = p_off_pos
	load_t = p_load_t
	focus_t = p_focus_t
	focus_width_t = p_focus_width_t
	focus_scale = p_focus_scale
	global_position = start_pos - size * 0.5
	visible = true


func update_item(now_ms: int) -> bool:
	var age_s: float = float(now_ms - spawn_ms) / 1000.0
	var t: float = age_s / travel_time_s
	
	if t >= 1.0:
		return false
	
	t = clamp(t, 0.0, 1.0)
	
	var p := start_pos.lerp(off_pos, t)
	global_position = p - size * 0.5
	
	# Focus scaling
	var focus_amt: float = 1.0 - (abs(t - focus_t) / max(focus_width_t, 0.0001))
	focus_amt = clamp(focus_amt, 0.0, 1.0)
	
	var s: float = lerp(1.0, focus_scale, focus_amt)
	scale = Vector2(s, s)
	
	if not focused and t >= focus_t:
		focused = true
		#future hook
		
	return true
