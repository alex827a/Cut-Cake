class_name GameProgress
extends RefCounted

const SAVE_PATH := "user://progress.cfg"
const SAVE_SECTION := "progress"
const UNLOCKED_KEY := "highest_unlocked_level"
const PROTOTYPE_UNLOCKED_KEY := "prototype_highest_unlocked_level"
const ENDLESS_UNLOCKED_KEY := "endless_unlocked"
const BEST_ENDLESS_SCORE_KEY := "best_endless_score"

static var _levels: Array[LevelConfig] = [
	LevelConfig.new(8, 300.0, 190.0, 140.0, 24.0),
	LevelConfig.new(8, 288.0, 205.0, 150.0, 24.0),
	LevelConfig.new(9, 276.0, 220.0, 160.0, 23.0),
	LevelConfig.new(9, 264.0, 235.0, 170.0, 22.0),
	LevelConfig.new(10, 252.0, 250.0, 175.0, 22.0),
	LevelConfig.new(10, 240.0, 265.0, 185.0, 21.0),
	LevelConfig.new(11, 228.0, 280.0, 195.0, 20.0),
	LevelConfig.new(11, 216.0, 300.0, 205.0, 19.0),
	LevelConfig.new(12, 204.0, 320.0, 215.0, 18.0),
	LevelConfig.new(12, 192.0, 340.0, 225.0, 18.0),
	LevelConfig.new(13, 184.0, 355.0, 230.0, 17.5),
	LevelConfig.new(13, 176.0, 370.0, 235.0, 17.0),
	LevelConfig.new(14, 168.0, 385.0, 240.0, 16.5),
	LevelConfig.new(14, 160.0, 400.0, 245.0, 16.0),
	LevelConfig.new(15, 154.0, 420.0, 250.0, 15.5),
	LevelConfig.new(15, 148.0, 440.0, 255.0, 15.0),
	LevelConfig.new(16, 142.0, 460.0, 260.0, 14.5),
	LevelConfig.new(17, 136.0, 480.0, 270.0, 14.0),
	LevelConfig.new(18, 130.0, 500.0, 280.0, 13.5),
	LevelConfig.new(20, 124.0, 525.0, 290.0, 13.0)
]

static var _loaded := false
static var current_level_index := 0
static var highest_unlocked_level_index := 0
static var prototype_current_level_index := 0
static var prototype_highest_unlocked_level_index := 0
static var endless_mode_unlocked := false
static var best_endless_score := 0
static var current_game_mode := GameMode.Type.LEVEL

static func ensure_loaded() -> void:
	if _loaded:
		return

	highest_unlocked_level_index = 0
	current_level_index = 0
	prototype_highest_unlocked_level_index = 0
	prototype_current_level_index = 0
	endless_mode_unlocked = false
	best_endless_score = 0
	current_game_mode = GameMode.Type.LEVEL

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		highest_unlocked_level_index = clampi(int(config.get_value(SAVE_SECTION, UNLOCKED_KEY, 0)), 0, _levels.size() - 1)
		prototype_highest_unlocked_level_index = maxi(0, int(config.get_value(SAVE_SECTION, PROTOTYPE_UNLOCKED_KEY, 0)))
		best_endless_score = maxi(0, int(config.get_value(SAVE_SECTION, BEST_ENDLESS_SCORE_KEY, 0)))

	endless_mode_unlocked = false

	_loaded = true

static func get_current_level() -> LevelConfig:
	ensure_loaded()
	return _levels[current_level_index]

static func start_game() -> void:
	ensure_loaded()
	current_game_mode = GameMode.Type.LEVEL
	current_level_index = 0

static func continue_game() -> void:
	ensure_loaded()
	current_game_mode = GameMode.Type.LEVEL
	current_level_index = highest_unlocked_level_index

static func set_current_level(level_index: int) -> void:
	ensure_loaded()
	current_game_mode = GameMode.Type.LEVEL
	current_level_index = clampi(level_index, 0, highest_unlocked_level_index)

static func start_endless_mode() -> void:
	ensure_loaded()
	endless_mode_unlocked = false
	current_game_mode = GameMode.Type.LEVEL
	current_level_index = 0

static func has_next_level(from_level_index: int) -> bool:
	return from_level_index < _levels.size() - 1

static func advance_to_next_level() -> bool:
	ensure_loaded()
	if not has_next_level(current_level_index):
		return false
	current_level_index += 1
	return true

static func complete_current_level() -> void:
	ensure_loaded()
	var next_unlocked_level := mini(current_level_index + 1, _levels.size() - 1)
	var progression_changed := false

	if next_unlocked_level > highest_unlocked_level_index:
		highest_unlocked_level_index = next_unlocked_level
		progression_changed = true

	if progression_changed:
		save()

static func try_set_best_endless_score(score: int) -> bool:
	ensure_loaded()
	if score <= best_endless_score:
		return false
	best_endless_score = score
	save()
	return true

static func get_total_levels() -> int:
	return _levels.size()

static func start_prototype_game() -> void:
	ensure_loaded()
	prototype_current_level_index = 0

static func continue_prototype_game(total_levels: int) -> void:
	ensure_loaded()
	var last_level_index := maxi(total_levels - 1, 0)
	prototype_current_level_index = clampi(prototype_highest_unlocked_level_index, 0, last_level_index)

static func set_current_prototype_level(level_index: int, total_levels: int) -> void:
	ensure_loaded()
	var last_level_index := maxi(total_levels - 1, 0)
	var highest_available_index := clampi(prototype_highest_unlocked_level_index, 0, last_level_index)
	prototype_current_level_index = clampi(level_index, 0, highest_available_index)

static func complete_prototype_level(total_levels: int) -> void:
	ensure_loaded()
	var last_level_index := maxi(total_levels - 1, 0)
	var current_index := clampi(prototype_current_level_index, 0, last_level_index)
	var next_unlocked_level := mini(current_index + 1, last_level_index)
	if next_unlocked_level > prototype_highest_unlocked_level_index:
		prototype_highest_unlocked_level_index = next_unlocked_level
		save()

static func save() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, UNLOCKED_KEY, highest_unlocked_level_index)
	config.set_value(SAVE_SECTION, PROTOTYPE_UNLOCKED_KEY, prototype_highest_unlocked_level_index)
	config.set_value(SAVE_SECTION, ENDLESS_UNLOCKED_KEY, endless_mode_unlocked)
	config.set_value(SAVE_SECTION, BEST_ENDLESS_SCORE_KEY, best_endless_score)
	var result := config.save(SAVE_PATH)
	if result != OK:
		push_warning("Failed to save progression to %s: %s" % [SAVE_PATH, result])
