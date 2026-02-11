### ScrollingItem.gd
extends Panel
class_name ScrollingItem

var progress: float = 0.0
var elapsed_s: float = 0.0
var travel_time_s: float

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
	
	if progress >= 1.0:
		return false
	
	var p := start_pos.lerp(off_pos, progress)
	global_position = p - size * 0.5
	
	var focus_amt: float = 1.0 - (abs(progress - focus_t) / max(focus_width_t, 0.0001))
	focus_amt = clamp(focus_amt, 0.0, 1.0)
	
	var s: float = lerp(1.0, focus_scale, focus_amt)
	scale = Vector2(s, s)
	
	return true


func _arm() -> void:
	if label:
		label.add_theme_color_override("font_color", armed_color)

func _disarm() -> void:
	if label:
		label.add_theme_color_override("font_color", disarmed_color)
