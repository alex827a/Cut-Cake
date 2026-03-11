class_name PrototypeLevelCatalog
extends Resource

@export var levels: Array[Resource] = []

func get_level_count() -> int:
	var valid_count := 0
	for entry in levels:
		if entry is PrototypeLevelConfig:
			valid_count += 1
	if valid_count > 0:
		return valid_count
	return get_default_levels().size()

func get_level(index: int) -> PrototypeLevelConfig:
	var valid_levels: Array[PrototypeLevelConfig] = []
	for entry in levels:
		var level := entry as PrototypeLevelConfig
		if level != null:
			valid_levels.append(level)

	if valid_levels.is_empty():
		valid_levels = get_default_levels()

	var safe_index := clampi(index, 0, valid_levels.size() - 1)
	return valid_levels[safe_index]

func get_default_levels() -> Array[PrototypeLevelConfig]:
	var data: Array[Array] = [
		[1, 180.0, 6, 280.0, 340.0, 92.0, 34.0, 0.02, 5],
		[2, 190.0, 7, 270.0, 330.0, 88.0, 32.0, 0.03, 5],
		[3, 200.0, 8, 260.0, 320.0, 84.0, 30.0, 0.04, 4],
		[4, 212.0, 8, 245.0, 305.0, 80.0, 28.0, 0.05, 4],
		[5, 224.0, 9, 235.0, 295.0, 76.0, 26.0, 0.06, 4],
		[6, 236.0, 9, 225.0, 285.0, 72.0, 24.0, 0.07, 4],
		[7, 248.0, 10, 215.0, 275.0, 68.0, 23.0, 0.08, 3],
		[8, 260.0, 10, 205.0, 265.0, 64.0, 22.0, 0.09, 3],
		[9, 272.0, 11, 200.0, 255.0, 60.0, 20.0, 0.10, 3],
		[10, 286.0, 11, 190.0, 245.0, 56.0, 19.0, 0.11, 3],
		[11, 300.0, 12, 185.0, 235.0, 52.0, 18.0, 0.12, 2],
		[12, 316.0, 12, 175.0, 225.0, 48.0, 17.0, 0.13, 2],
		[13, 332.0, 13, 170.0, 215.0, 44.0, 16.0, 0.14, 2],
		[14, 348.0, 13, 165.0, 205.0, 40.0, 15.0, 0.15, 2],
		[15, 364.0, 14, 160.0, 195.0, 36.0, 14.0, 0.16, 1]
	]

	var built_levels: Array[PrototypeLevelConfig] = []
	for row in data:
		var level := PrototypeLevelConfig.new()
		level.level_number = int(row[0])
		level.conveyor_speed = float(row[1])
		level.cake_count = int(row[2])
		level.min_gap = float(row[3])
		level.max_gap = float(row[4])
		level.cut_zone_size = float(row[5])
		level.perfect_zone_size = float(row[6])
		level.cake_size_variation = float(row[7])
		level.allowed_misses = int(row[8])
		built_levels.append(level)

	return built_levels
