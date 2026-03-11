class_name CutCrumb
extends Polygon2D

@export var velocity: Vector2 = Vector2.ZERO
@export var gravity: float = 520.0
@export var angular_velocity: float = 0.0
@export var lifetime: float = 0.42
@export var start_scale: float = 1.0
@export var end_scale: float = 0.2
@export var preserve_after_settle: bool = false
@export var settle_y: float = -1.0
@export var settle_spread_y: float = 0.0
@export var settle_x_drift: float = 0.0
@export var settled_alpha: float = 0.94
@export var settled_z_index: int = 1

var _age: float = 0.0
var _settled: bool = false
var _target_settle_y: float = -1.0

func _enter_tree() -> void:
	top_level = true
	add_to_group("cut_scraps")

func _ready() -> void:
	if preserve_after_settle and settle_y >= 0.0:
		_target_settle_y = settle_y + randf_range(-settle_spread_y, settle_spread_y)

func _physics_process(delta: float) -> void:
	if _settled:
		return

	global_position += velocity * delta
	velocity.y += gravity * delta
	rotation += angular_velocity * delta

	_age += delta
	var t: float = clampf(_age / maxf(lifetime, 0.001), 0.0, 1.0)
	scale = Vector2.ONE * lerpf(start_scale, end_scale, t)

	if preserve_after_settle:
		modulate.a = 1.0
		if _target_settle_y >= 0.0 and global_position.y >= _target_settle_y:
			_settle()
			return
		if global_position.y > 1800.0:
			queue_free()
		return

	modulate.a = 1.0 - t
	if _age >= lifetime or global_position.y > 1400.0:
		queue_free()

func _settle() -> void:
	_settled = true
	global_position = Vector2(global_position.x + randf_range(-settle_x_drift, settle_x_drift), _target_settle_y)
	velocity = Vector2.ZERO
	angular_velocity = 0.0
	scale = Vector2.ONE * maxf(end_scale, start_scale * 0.58)
	modulate.a = settled_alpha
	z_index = settled_z_index
