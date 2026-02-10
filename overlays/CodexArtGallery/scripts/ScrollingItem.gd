extends Panel
class_name ScrollingItem

const ITEM_SIZE := Vector2(512, 512)

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
