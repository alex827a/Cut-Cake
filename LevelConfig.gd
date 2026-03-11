class_name LevelConfig
extends RefCounted

var required_blocks_to_win: int
var initial_block_width: float
var block_move_speed: float
var horizontal_move_range: float
var min_valid_overlap: float

func _init(new_required_blocks_to_win: int, new_initial_block_width: float, new_block_move_speed: float, new_horizontal_move_range: float, new_min_valid_overlap: float) -> void:
	required_blocks_to_win = new_required_blocks_to_win
	initial_block_width = new_initial_block_width
	block_move_speed = new_block_move_speed
	horizontal_move_range = new_horizontal_move_range
	min_valid_overlap = new_min_valid_overlap
