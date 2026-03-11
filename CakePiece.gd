class_name CakePiece
extends Node2D

@export var move_speed: float = 220.0
@export var piece_size: Vector2 = Vector2(80.0, 48.0)
@export var source_texture: Texture2D
@export var texture_region: Rect2 = Rect2(0.0, 0.0, 120.0, 120.0)
@export var uniform_scale: float = 1.0
@export var sprite_top_offset: float = -54.0
@export var is_left_piece: bool = true
@export var initial_velocity: Vector2 = Vector2(220.0, 0.0)
@export var gravity: float = 180.0
@export var angular_velocity: float = 0.0

@onready var body: Sprite2D = $Body
@onready var cut_face: ColorRect = $CutFace
@onready var cut_edge: Polygon2D = $CutEdge
@onready var crumb_a: Polygon2D = $CrumbA
@onready var crumb_b: Polygon2D = $CrumbB

var _velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("cake_pieces")
	_velocity = initial_velocity
	_apply_visuals()

func _process(delta: float) -> void:
	position += _velocity * delta
	_velocity.y += gravity * delta
	rotation += angular_velocity * delta
	if position.x > 1600.0 or position.y > 1200.0:
		queue_free()

func _apply_visuals() -> void:
	if source_texture == null:
		body.visible = false
		cut_face.visible = false
		return

	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = source_texture
	atlas.region = texture_region

	body.visible = true
	body.texture = atlas
	body.centered = false
	body.position = Vector2(-piece_size.x * 0.5, sprite_top_offset)
	body.scale = Vector2.ONE * uniform_scale

	cut_face.visible = false
	_apply_cut_edge_visuals()

func refresh_visuals() -> void:
	_apply_visuals()

func _apply_cut_edge_visuals() -> void:
	var seam_x: float = piece_size.x * 0.5 if is_left_piece else -piece_size.x * 0.5
	var face_depth: float = 12.0
	var top_y: float = -piece_size.y * 0.5 - 8.0
	var bottom_y: float = piece_size.y * 0.5 + 10.0
	var jagged_points: Array[Vector2] = [
		Vector2(seam_x, top_y),
		Vector2(seam_x + (-7.0 if is_left_piece else 7.0), top_y + 8.0),
		Vector2(seam_x + (1.5 if is_left_piece else -1.5), top_y + 15.0),
		Vector2(seam_x + (-6.5 if is_left_piece else 6.5), top_y + 24.0),
		Vector2(seam_x + (3.5 if is_left_piece else -3.5), top_y + 34.0),
		Vector2(seam_x + (-5.0 if is_left_piece else 5.0), top_y + 43.0),
		Vector2(seam_x + (2.0 if is_left_piece else -2.0), top_y + 51.0),
		Vector2(seam_x + (-4.5 if is_left_piece else 4.5), bottom_y)
	]
	var back_x: float = seam_x - face_depth if is_left_piece else seam_x + face_depth
	var polygon_points: PackedVector2Array = PackedVector2Array()
	polygon_points.append(Vector2(back_x, top_y))
	for point in jagged_points:
		polygon_points.append(point)
	polygon_points.append(Vector2(back_x, bottom_y))
	cut_edge.visible = true
	cut_edge.color = Color(0.9, 0.71, 0.54, 0.98)
	cut_edge.polygon = polygon_points

	crumb_a.visible = false
	crumb_b.visible = false
