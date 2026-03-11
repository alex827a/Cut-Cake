class_name KnifeController
extends Node2D

signal cut_resolved(result: String, distance: float, world_position: Vector2, resolved_cake: bool)

@export var drop_distance: float = 300.0
@export var drop_duration: float = 0.08
@export var reset_duration: float = 0.12
@export var target_y: float = 420.0
@export var cake_piece_scene: PackedScene

var _busy: bool = false
var _start_position: Vector2 = Vector2.ZERO
var _spawner: CakeSpawner

func _ready() -> void:
	_start_position = global_position
	_spawner = get_parent().get_node("Spawner") as CakeSpawner

func try_drop() -> void:
	if _busy:
		return

	_busy = true
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position:y", _start_position.y + drop_distance, drop_duration)
	tween.tween_callback(_check_cut)
	tween.tween_property(self, "global_position:y", _start_position.y, reset_duration)
	tween.tween_callback(_finish_drop)

func _check_cut() -> void:
	if _spawner == null:
		cut_resolved.emit("Miss", -1.0, global_position, false)
		return

	var cake: MovingCake = _spawner.get_closest_cake_at_x(global_position.x)
	if cake == null:
		cut_resolved.emit("Miss", -1.0, global_position, false)
		return

	var evaluation: Dictionary = cake.evaluate_cut(global_position.x)
	var result: String = String(evaluation["result"])
	var distance: float = float(evaluation["distance"])
	var hit_world_position: Vector2 = cake.global_position
	var resolved_cake: bool = result == "Miss"
	if result != "Miss":
		cake.was_cut = true
		cake.split(float(evaluation["local_x"]), cake_piece_scene, result)
	else:
		cake.was_cut = true

	print("Cut result: %s | distance: %.2f" % [result, distance])
	cut_resolved.emit(result, distance, hit_world_position, resolved_cake)

func _finish_drop() -> void:
	_busy = false
