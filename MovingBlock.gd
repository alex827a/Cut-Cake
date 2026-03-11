class_name MovingBlock
extends Node2D

@export var height := 32.0
@export var fill_color := Color.WHITE
@export var texture_width_visual_multiplier := 1.0
@export var texture_height_visual_multiplier := 1.0

var _body: Polygon2D
var _shadow: Polygon2D
var _highlight: Polygon2D
var _glow_sprite: Sprite2D
var _sprite: Sprite2D
var _is_moving := false
var _move_speed := 0.0
var _move_range := 0.0
var _origin_x := 0.0
var _direction := 1.0
var _width := 220.0
var _block_texture: Texture2D

var width: float:
	get:
		return _width

var block_texture: Texture2D:
	get:
		return _block_texture

var center_x: float:
	get:
		return global_position.x

var left_x: float:
	get:
		return center_x - (_width * 0.5)

var right_x: float:
	get:
		return center_x + (_width * 0.5)

func _ready() -> void:
	_body = get_node("Body")
	_shadow = get_node("Shadow")
	_highlight = get_node("Highlight")
	_glow_sprite = get_node("GlowSprite")
	_sprite = get_node("Sprite")
	apply_visuals()

func _process(delta: float) -> void:
	if not _is_moving:
		return

	var next_position := position
	next_position.x += _move_speed * delta * _direction
	var left_limit := _origin_x - _move_range
	var right_limit := _origin_x + _move_range

	if next_position.x <= left_limit:
		next_position.x = left_limit
		_direction = 1.0
	elif next_position.x >= right_limit:
		next_position.x = right_limit
		_direction = -1.0

	position = next_position

func set_width(value: float) -> void:
	_width = maxf(value, 1.0)
	apply_visuals()

func set_height(value: float) -> void:
	height = maxf(value, 1.0)
	apply_visuals()

func set_block_color(color: Color) -> void:
	fill_color = color
	apply_visuals()

func set_block_texture(texture: Texture2D) -> void:
	_block_texture = texture
	apply_visuals()

func start_movement(origin_x: float, move_speed: float, move_range: float, phase_offset: float = 0.0) -> void:
	_origin_x = origin_x
	_move_speed = move_speed
	_move_range = maxf(move_range, 0.0)
	_direction = 1.0 if cos(phase_offset) >= 0.0 else -1.0
	_is_moving = true
	_glow_sprite.visible = true

	var next_position := position
	next_position.x = _origin_x + (sin(phase_offset) * _move_range)
	position = next_position

	if _move_range <= 0.0 or _move_speed <= 0.0:
		next_position.x = _origin_x
		position = next_position

func stop_movement() -> void:
	_is_moving = false
	_glow_sprite.visible = false

func snap_to(center_x_value: float, center_y: float) -> void:
	global_position = Vector2(center_x_value, center_y)

func apply_visuals() -> void:
	if _body == null or _sprite == null:
		return

	var half_width := _width * 0.5
	var half_height := height * 0.5
	var textured_width := _width * texture_width_visual_multiplier if _block_texture != null else _width
	var textured_height := height * texture_height_visual_multiplier if _block_texture != null else height
	var textured_half_width := textured_width * 0.5
	var textured_half_height := textured_height * 0.5

	var shadow_source_width := textured_width if _block_texture != null else _width
	var shadow_source_height := textured_height if _block_texture != null else height
	var shadow_half_width := maxf(shadow_source_width * 0.36, 24.0)
	var shadow_half_height := clampf(shadow_source_height * 0.1, 4.0, 12.0)
	var shadow_y_offset := textured_half_height + shadow_half_height + 2.0
	_shadow.position = Vector2(0.0, shadow_y_offset)
	_shadow.color = Color(0.24, 0.16, 0.18, 0.12)
	_shadow.polygon = PackedVector2Array([
		Vector2(-shadow_half_width, 0.0),
		Vector2(-shadow_half_width * 0.76, -shadow_half_height * 0.68),
		Vector2(-shadow_half_width * 0.26, -shadow_half_height),
		Vector2(shadow_half_width * 0.26, -shadow_half_height),
		Vector2(shadow_half_width * 0.76, -shadow_half_height * 0.68),
		Vector2(shadow_half_width, 0.0),
		Vector2(shadow_half_width * 0.76, shadow_half_height * 0.68),
		Vector2(shadow_half_width * 0.26, shadow_half_height),
		Vector2(-shadow_half_width * 0.26, shadow_half_height),
		Vector2(-shadow_half_width * 0.76, shadow_half_height * 0.68)
	])

	var highlight_height := minf(textured_height * 0.14, 12.0)
	var highlight_top := -textured_half_height + 3.0
	_highlight.polygon = PackedVector2Array([
		Vector2(-textured_half_width + 14.0, highlight_top),
		Vector2(textured_half_width - 14.0, highlight_top),
		Vector2(textured_half_width - 30.0, highlight_top + highlight_height),
		Vector2(-textured_half_width + 30.0, highlight_top + highlight_height)
	])

	_sprite.texture = _block_texture
	_sprite.visible = _block_texture != null
	_sprite.modulate = fill_color

	if _block_texture != null:
		var texture_size := _block_texture.get_size()
		var safe_width := maxf(texture_size.x, 1.0)
		var safe_height := maxf(texture_size.y, 1.0)
		_sprite.scale = Vector2(textured_width / safe_width, textured_height / safe_height)
		_glow_sprite.texture = _block_texture
		_glow_sprite.scale = Vector2((textured_width / safe_width) * 1.06, (textured_height / safe_height) * 1.1)
		_glow_sprite.modulate = Color(1.0, 0.96, 0.88, 0.3)
	else:
		_sprite.scale = Vector2.ONE
		_glow_sprite.texture = null
		_glow_sprite.scale = Vector2.ONE

	_body.visible = _block_texture == null
	_body.color = fill_color
	_body.polygon = PackedVector2Array([
		Vector2(-half_width, -half_height),
		Vector2(half_width, -half_height),
		Vector2(half_width, half_height),
		Vector2(-half_width, half_height)
	])
