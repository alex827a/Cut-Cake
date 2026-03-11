class_name CakeSpawner
extends Node2D

@export var cake_scene: PackedScene
@export var spawn_x: float = -220.0
@export var spawn_y: float = 420.0
@export var conveyor_speed: float = 220.0
@export var min_cut_zone_offset: float = -42.0
@export var max_cut_zone_offset: float = 42.0

var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_cycle_index: int = 0

func _ready() -> void:
	_random.randomize()
	CakeUnlockManager.ensure_loaded()

func reset_cake_cycle() -> void:
	_spawn_cycle_index = 0

func spawn_cake(level_config: PrototypeLevelConfig) -> MovingCake:
	if cake_scene == null:
		return null

	var cake: MovingCake = cake_scene.instantiate() as MovingCake
	var size_scale: float = 1.0 + _random.randf_range(-level_config.cake_size_variation, level_config.cake_size_variation)
	var base_cake_size: Vector2 = cake.cake_size
	var cake_texture: Texture2D = CakeUnlockManager.get_prototype_cake_texture_for_spawn(_spawn_cycle_index)
	cake.position = Vector2(spawn_x, spawn_y)
	cake.move_speed = level_config.conveyor_speed
	cake.good_hit_half_width = level_config.cut_zone_size * 0.5
	cake.perfect_hit_half_width = level_config.perfect_zone_size * 0.5
	cake.cut_zone_offset_x = _random.randf_range(min_cut_zone_offset, max_cut_zone_offset)
	cake.cake_size = Vector2(base_cake_size.x * size_scale, base_cake_size.y)
	cake.cake_texture = cake_texture
	get_parent().add_child(cake)
	_spawn_cycle_index += 1
	return cake

func get_spawn_delay(level_config: PrototypeLevelConfig) -> float:
	var gap: float = _random.randf_range(level_config.min_gap, level_config.max_gap)
	return gap / maxf(level_config.conveyor_speed, 1.0)

func get_closest_cake_at_x(world_x: float, max_distance: float = 120.0) -> MovingCake:
	var closest_cake: MovingCake = null
	var closest_distance: float = max_distance

	for node in get_tree().get_nodes_in_group("cakes"):
		var cake: MovingCake = node as MovingCake
		if cake == null or cake.was_cut:
			continue

		var distance: float = absf(cake.global_position.x - world_x)
		if distance <= closest_distance:
			closest_distance = distance
			closest_cake = cake

	return closest_cake
