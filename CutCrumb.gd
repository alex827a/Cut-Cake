class_name CutCrumb
extends Polygon2D

@export var velocity: Vector2 = Vector2.ZERO
@export var gravity: float = 520.0
@export var angular_velocity: float = 0.0
@export var lifetime: float = 0.42
@export var start_scale: float = 1.0
@export var end_scale: float = 0.2

var _age: float = 0.0

func _enter_tree() -> void:
	top_level = true

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	velocity.y += gravity * delta
	rotation += angular_velocity * delta

	_age += delta
	var t: float = clampf(_age / lifetime, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(start_scale, end_scale, t)
	modulate.a = 1.0 - t

	if _age >= lifetime or global_position.y > 1400.0:
		queue_free()
