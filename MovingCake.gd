class_name MovingCake
extends Node2D

const CUT_CRUMB_SCRIPT: GDScript = preload("res://CutCrumb.gd")

signal exited_uncut

@export var move_speed: float = 220.0
@export var cake_size: Vector2 = Vector2(180.0, 64.0)
@export var good_hit_half_width: float = 34.0
@export var perfect_hit_half_width: float = 10.0
@export var cut_zone_offset_x: float = 0.0
@export var cut_zone_height: float = 64.0
@export var cake_texture: Texture2D
@export var fill_color: Color = Color(1.0, 0.78, 0.84, 1.0)
@export var crust_color: Color = Color(0.67, 0.42, 0.25, 1.0)

@onready var shadow: Polygon2D = $Shadow
@onready var cake_sprite: Sprite2D = $CakeSprite
@onready var base_layer: Polygon2D = $BaseLayer
@onready var cream_layer: Polygon2D = $CreamLayer
@onready var middle_layer: Polygon2D = $MiddleLayer
@onready var frosting: Polygon2D = $Frosting
@onready var frosting_highlight: Polygon2D = $FrostingHighlight
@onready var topping_cream: Polygon2D = $ToppingCream
@onready var topping_berry: Polygon2D = $ToppingBerry
@onready var cut_zone_shape: CollisionShape2D = $CutZone/CollisionShape2D
@onready var perfect_zone_shape: CollisionShape2D = $PerfectZone/CollisionShape2D
@onready var hit_shape: CollisionShape2D = $HitBox/CollisionShape2D
@onready var good_ring: ColorRect = $GoodRing
@onready var perfect_ring: ColorRect = $PerfectRing

var was_cut: bool = false
var _is_splitting: bool = false

func _get_full_sprite_display_size() -> Vector2:
	if cake_sprite == null or cake_sprite.texture == null:
		return Vector2(cake_size.x, cake_size.y)
	var sprite_size: Vector2 = cake_sprite.texture.get_size()
	var uniform_scale: float = cake_size.x / maxf(sprite_size.x, 1.0)
	return sprite_size * uniform_scale

func _get_uniform_sprite_scale() -> float:
	if cake_sprite == null or cake_sprite.texture == null:
		return 1.0
	return cake_size.x / maxf(cake_sprite.texture.get_size().x, 1.0)

func _ready() -> void:
	add_to_group("cakes")
	_apply_visuals()

func _process(delta: float) -> void:
	if _is_splitting:
		return
	position.x += move_speed * delta
	if position.x > 1600.0:
		if not was_cut:
			exited_uncut.emit()
		queue_free()

func _apply_visuals() -> void:
	if cake_texture != null:
		cake_sprite.texture = cake_texture

	var good_half_width: float = maxf(good_hit_half_width, 1.0)
	var perfect_half_width: float = clampf(perfect_hit_half_width, 1.0, good_half_width)
	var half_width: float = cake_size.x * 0.5
	var half_height: float = cake_size.y * 0.5
	var sprite_size: Vector2 = cake_sprite.texture.get_size() if cake_sprite.texture != null else Vector2.ONE
	var full_display_size: Vector2 = _get_full_sprite_display_size()

	cake_sprite.visible = true
	cake_sprite.scale = Vector2.ONE * (full_display_size.x / maxf(sprite_size.x, 1.0))
	cake_sprite.position = Vector2(0.0, -12.0)

	shadow.scale = Vector2(maxf(cake_size.x / 168.0, 0.6), 1.0)
	base_layer.visible = false
	base_layer.color = crust_color.darkened(0.04)
	base_layer.polygon = PackedVector2Array([
		Vector2(-half_width + 8.0, -half_height * 0.28),
		Vector2(-half_width + 22.0, -half_height * 0.72),
		Vector2(half_width - 22.0, -half_height * 0.72),
		Vector2(half_width - 8.0, -half_height * 0.28),
		Vector2(half_width - 8.0, half_height * 0.58),
		Vector2(half_width - 22.0, half_height * 0.95),
		Vector2(-half_width + 22.0, half_height * 0.95),
		Vector2(-half_width + 8.0, half_height * 0.58)
	])

	cream_layer.color = fill_color.lightened(0.12)
	cream_layer.visible = false
	cream_layer.polygon = PackedVector2Array([
		Vector2(-half_width + 12.0, -half_height * 0.2),
		Vector2(-half_width + 24.0, -half_height * 0.62),
		Vector2(half_width - 24.0, -half_height * 0.62),
		Vector2(half_width - 12.0, -half_height * 0.2),
		Vector2(half_width - 12.0, half_height * 0.38),
		Vector2(half_width - 24.0, half_height * 0.76),
		Vector2(-half_width + 24.0, half_height * 0.76),
		Vector2(-half_width + 12.0, half_height * 0.38)
	])

	middle_layer.color = crust_color.lightened(0.18)
	middle_layer.visible = false
	middle_layer.polygon = PackedVector2Array([
		Vector2(-half_width + 16.0, -half_height * 0.04),
		Vector2(-half_width + 28.0, -half_height * 0.44),
		Vector2(half_width - 28.0, -half_height * 0.44),
		Vector2(half_width - 16.0, -half_height * 0.04),
		Vector2(half_width - 16.0, half_height * 0.34),
		Vector2(half_width - 28.0, half_height * 0.66),
		Vector2(-half_width + 28.0, half_height * 0.66),
		Vector2(-half_width + 16.0, half_height * 0.34)
	])

	frosting.color = fill_color.lightened(0.24)
	frosting.visible = false
	frosting.scale = Vector2(maxf(cake_size.x / 180.0, 0.75), maxf(cake_size.y / 64.0, 0.8))
	frosting_highlight.visible = false
	frosting_highlight.scale = frosting.scale
	topping_cream.visible = false
	topping_cream.scale = Vector2(maxf(cake_size.x / 180.0, 0.8), maxf(cake_size.y / 64.0, 0.8))
	topping_berry.position = Vector2(cake_size.x * 0.06, -cake_size.y * 0.82)
	topping_berry.visible = false
	topping_berry.scale = Vector2(maxf(cake_size.x / 180.0, 0.8), maxf(cake_size.y / 64.0, 0.8))

	var zone_rect: RectangleShape2D = RectangleShape2D.new()
	zone_rect.size = Vector2(good_half_width * 2.0, cut_zone_height)
	cut_zone_shape.shape = zone_rect
	cut_zone_shape.position = Vector2(cut_zone_offset_x, 0.0)

	var perfect_rect: RectangleShape2D = RectangleShape2D.new()
	perfect_rect.size = Vector2(perfect_half_width * 2.0, cut_zone_height)
	perfect_zone_shape.shape = perfect_rect
	perfect_zone_shape.position = Vector2(cut_zone_offset_x, 0.0)

	var hit_rect: RectangleShape2D = RectangleShape2D.new()
	hit_rect.size = cake_size
	hit_shape.shape = hit_rect

	good_ring.size = zone_rect.size
	good_ring.position = Vector2(cut_zone_offset_x - good_half_width, -cut_zone_height * 0.5)
	good_ring.color = Color(1.0, 0.74, 0.22, 0.26)
	perfect_ring.size = perfect_rect.size
	perfect_ring.position = Vector2(cut_zone_offset_x - perfect_half_width, -cut_zone_height * 0.5)
	perfect_ring.color = Color(0.34, 0.96, 0.52, 0.34)

func evaluate_cut(knife_x: float) -> Dictionary:
	var local_x: float = knife_x - global_position.x
	var distance: float = absf(local_x - cut_zone_offset_x)
	var good_half_width: float = maxf(good_hit_half_width, 1.0)
	var perfect_half_width: float = clampf(perfect_hit_half_width, 1.0, good_half_width)
	var result: String = CutResolver.resolve(distance, perfect_half_width, good_half_width)
	return {
		"result": result,
		"local_x": local_x,
		"distance": distance,
		"cut_center_x": cut_zone_offset_x,
		"perfect_half_width": perfect_half_width,
		"good_half_width": good_half_width
	}

func split(cut_local_x: float, piece_scene: PackedScene) -> void:
	if piece_scene == null:
		queue_free()
		return

	_is_splitting = true
	var clamped_cut_x: float = clampf(cut_local_x, -cake_size.x * 0.45, cake_size.x * 0.45)
	var left_width: float = maxf(clamped_cut_x + (cake_size.x * 0.5), 12.0)
	var right_width: float = maxf(cake_size.x - left_width, 12.0)
	await _play_cut_feedback(clamped_cut_x)

	var uniform_scale: float = _get_uniform_sprite_scale()
	var source_left_width: float = left_width / maxf(uniform_scale, 0.001)
	var source_right_width: float = right_width / maxf(uniform_scale, 0.001)
	var sprite_top_offset: float = cake_sprite.position.y - (_get_full_sprite_display_size().y * 0.5)

	var left_piece: CakePiece = piece_scene.instantiate() as CakePiece
	var right_piece: CakePiece = piece_scene.instantiate() as CakePiece

	left_piece.move_speed = move_speed
	left_piece.initial_velocity = Vector2(move_speed - 72.0, -28.0)
	left_piece.angular_velocity = -2.0
	left_piece.piece_size = Vector2(left_width, cake_size.y)
	left_piece.source_texture = cake_sprite.texture
	left_piece.texture_region = Rect2(0.0, 0.0, source_left_width, cake_sprite.texture.get_size().y)
	left_piece.uniform_scale = uniform_scale
	left_piece.sprite_top_offset = sprite_top_offset
	left_piece.is_left_piece = true
	left_piece.global_position = global_position + Vector2((left_width * 0.5) - (cake_size.x * 0.5) - 10.0, -2.0)

	right_piece.move_speed = move_speed
	right_piece.initial_velocity = Vector2(move_speed + 72.0, -28.0)
	right_piece.angular_velocity = 2.0
	right_piece.piece_size = Vector2(right_width, cake_size.y)
	right_piece.source_texture = cake_sprite.texture
	right_piece.texture_region = Rect2(source_left_width, 0.0, source_right_width, cake_sprite.texture.get_size().y)
	right_piece.uniform_scale = uniform_scale
	right_piece.sprite_top_offset = sprite_top_offset
	right_piece.is_left_piece = false
	right_piece.global_position = global_position + Vector2((cake_size.x * 0.5) - (right_width * 0.5) + 10.0, -2.0)

	get_parent().add_child(left_piece)
	get_parent().add_child(right_piece)
	left_piece.refresh_visuals()
	right_piece.refresh_visuals()

	queue_free()

func _play_cut_feedback(cut_local_x: float) -> void:
	_spawn_cut_flash(cut_local_x)
	_spawn_cut_particles(cut_local_x)
	_play_cut_sound(cut_local_x)

	var origin: Vector2 = position
	var shake_offsets: Array[Vector2] = [
		Vector2(-6.0, 0.0),
		Vector2(6.0, -2.0),
		Vector2(-4.0, 2.0),
		Vector2(3.0, -1.0)
	]
	var tween: Tween = create_tween()
	for shake_offset in shake_offsets:
		tween.tween_property(self, "position", origin + shake_offset, 0.024).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", origin, 0.03).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func _spawn_cut_flash(cut_local_x: float) -> void:
	var flash_root: Node2D = Node2D.new()
	flash_root.position = Vector2(cut_local_x, -6.0)
	flash_root.z_index = 8
	add_child(flash_root)

	var flash_glow: Polygon2D = Polygon2D.new()
	flash_glow.polygon = PackedVector2Array([
		Vector2(0.0, -36.0),
		Vector2(18.0, 0.0),
		Vector2(0.0, 36.0),
		Vector2(-18.0, 0.0)
	])
	flash_glow.color = Color(1.0, 0.92, 0.55, 0.4)
	flash_root.add_child(flash_glow)

	var flash_core: Polygon2D = Polygon2D.new()
	flash_core.polygon = PackedVector2Array([
		Vector2(0.0, -24.0),
		Vector2(8.0, 0.0),
		Vector2(0.0, 24.0),
		Vector2(-8.0, 0.0)
	])
	flash_core.color = Color(1.0, 0.99, 0.9, 0.95)
	flash_root.add_child(flash_core)

	flash_root.scale = Vector2(0.35, 0.5)
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(flash_root, "scale", Vector2(1.0, 1.2), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	flash_tween.parallel().tween_property(flash_glow, "color:a", 0.0, 0.12)
	flash_tween.parallel().tween_property(flash_core, "color:a", 0.0, 0.1)
	flash_tween.finished.connect(flash_root.queue_free)

func _spawn_cut_particles(cut_local_x: float) -> void:
	var particles_parent: Node = get_tree().current_scene if get_tree().current_scene != null else get_parent()
	for particle_index in range(16):
		var particle: CutCrumb = CUT_CRUMB_SCRIPT.new()
		var is_cream_splash: bool = particle_index % 3 == 0
		var side_push: float = randf_range(34.0, 112.0) * (-1.0 if particle_index % 2 == 0 else 1.0)
		particle.top_level = true
		particle.z_index = 7
		particle.rotation = randf_range(-0.7, 0.7)
		if is_cream_splash:
			particle.color = Color(1.0, 0.9, 0.84, 0.9) if particle_index % 2 == 0 else Color(0.98, 0.8, 0.84, 0.88)
			particle.polygon = PackedVector2Array([
				Vector2(0.0, -7.5),
				Vector2(4.0, -4.0),
				Vector2(6.5, 0.0),
				Vector2(4.5, 5.5),
				Vector2(0.5, 7.0),
				Vector2(-4.5, 4.0),
				Vector2(-6.0, -1.0),
				Vector2(-3.0, -6.0)
			])
			particle.velocity = Vector2(side_push + randf_range(-42.0, 42.0), randf_range(-228.0, -138.0))
			particle.angular_velocity = randf_range(-4.4, 4.4)
			particle.gravity = randf_range(460.0, 620.0)
			particle.lifetime = randf_range(0.6, 0.84)
			particle.start_scale = randf_range(1.0, 1.55)
			particle.end_scale = randf_range(0.18, 0.28)
		else:
			particle.color = Color(0.97, 0.86, 0.68, 0.95) if particle_index % 2 == 0 else Color(0.89, 0.66, 0.46, 0.92)
			particle.polygon = PackedVector2Array([
				Vector2(0.0, -5.5),
				Vector2(4.5, -1.5),
				Vector2(5.5, 3.0),
				Vector2(1.0, 5.5),
				Vector2(-4.0, 2.0)
			])
			particle.velocity = Vector2(side_push + randf_range(-58.0, 58.0), randf_range(-198.0, -104.0))
			particle.angular_velocity = randf_range(-6.2, 6.2)
			particle.gravity = randf_range(560.0, 760.0)
			particle.lifetime = randf_range(0.52, 0.74)
			particle.start_scale = randf_range(0.9, 1.35)
			particle.end_scale = randf_range(0.14, 0.22)
		particles_parent.add_child(particle)
		particle.global_position = global_position + Vector2(cut_local_x + randf_range(-10.0, 10.0), randf_range(-22.0, 12.0))

func _play_cut_sound(cut_local_x: float) -> void:
	if not AppSettings.sound_enabled:
		return

	var sound_player := AudioStreamPlayer2D.new()
	sound_player.stream = ToneFactory.create_cake_slice_sound()
	sound_player.bus = "Master"
	sound_player.volume_db = AppSettings.convert_linear_volume_to_db(clampf(AppSettings.volume, 0.0, 1.0)) + 10.5
	sound_player.position = global_position + Vector2(cut_local_x, 0.0)
	get_parent().add_child(sound_player)
	sound_player.play()
	sound_player.finished.connect(sound_player.queue_free)
