extends Node2D

@export var block_scene: PackedScene
@export var block_texture1: Texture2D
@export var block_texture2: Texture2D
@export var block_texture3: Texture2D
@export var block_texture4: Texture2D
@export var block_height_step := 48.0
@export var perfect_placement_threshold := 4.0
@export var near_perfect_placement_threshold := 12.0
@export var camera_ui_safe_padding := 28.0
@export var cut_fall_distance := 300.0
@export var cut_horizontal_drift := 72.0
@export var cut_fall_duration := 0.9

var _block_colors := [
	Color(0.20, 0.56, 0.95, 1.0),
	Color(0.15, 0.78, 0.67, 1.0),
	Color(0.96, 0.75, 0.22, 1.0),
	Color(0.95, 0.47, 0.31, 1.0),
	Color(0.70, 0.45, 0.95, 1.0)
]

var _camera: Camera2D
var _backdrop_top: ColorRect
var _backdrop_bottom: ColorRect
var _cake_plate: Sprite2D
var _cake_plate_shadow: Sprite2D
var _tower_shadow: Sprite2D
var _base_platform: MovingBlock
var _placed_blocks_root: Node2D
var _current_block_spawn: Marker2D
var _top_panel: PanelContainer
var _top_panel_margin: MarginContainer
var _top_row: HBoxContainer
var _status_panel: PanelContainer
var _action_buttons: HBoxContainer
var _level_label: Label
var _progress_label: Label
var _status_label: Label
var _restart_button: Button
var _next_level_button: Button
var _back_to_menu_button: Button
var _tap_hint_label: Label
var _perfect_label: Label
var _level_complete_label: Label
var _unlock_popup: Control
var _unlock_popup_label: Label
var _unlock_popup_preview: TextureRect
var _place_sound_player: AudioStreamPlayer
var _result_sound_player: AudioStreamPlayer
var _sprinkle_particles: CPUParticles2D
var _clouds: Array[Polygon2D] = []
var _cloud_base_offsets: Array[Vector2] = []
var _cloud_drift_speeds: Array[float] = []
var _default_block_textures: Array[Texture2D] = []
var _unlocked_cake_variants: Array[CakeVariantConfig] = []
var _random := RandomNumberGenerator.new()

var _base_platform_start_position := Vector2.ZERO
var _last_viewport_size := Vector2.ZERO
var _spawn_base_y := 0.0
var _camera_start_position := Vector2.ZERO
var _camera_base_position := Vector2.ZERO
var _highest_cloud_anchor_y := 0.0
var _game_active := false
var _placed_block_count := 0
var _active_level_index := 0
var _active_level: LevelConfig
var _game_mode := GameMode.Type.LEVEL
var _reference_block: MovingBlock
var _current_block: MovingBlock
var _camera_shake_time_left := 0.0
var _camera_shake_strength := 0.0

func _ready() -> void:
	_camera = get_node("Camera2D")
	_backdrop_top = get_node("BackdropTop")
	_backdrop_bottom = get_node("BackdropBottom")
	_cake_plate = get_node("CakePlate")
	_cake_plate_shadow = get_node("CakePlateShadow")
	_tower_shadow = get_node("TowerShadow")
	_base_platform = get_node("BasePlatform")
	_placed_blocks_root = get_node("PlacedBlocksRoot")
	_current_block_spawn = get_node("CurrentBlockSpawn")
	_top_panel = get_node("UI/TopPanel")
	_top_panel_margin = get_node("UI/TopPanel/Margin")
	_top_row = get_node("UI/TopPanel/Margin/TopRow")
	_status_panel = get_node("UI/StatusPanel")
	_action_buttons = get_node("UI/ActionButtons")
	_level_label = get_node("UI/TopPanel/Margin/TopRow/InfoBox/LevelLabel")
	_progress_label = get_node("UI/TopPanel/Margin/TopRow/InfoBox/ProgressLabel")
	_status_label = get_node("UI/StatusPanel/StatusLabel")
	_restart_button = get_node("UI/ActionButtons/RestartButton")
	_next_level_button = get_node("UI/ActionButtons/NextLevelButton")
	_back_to_menu_button = get_node("UI/TopPanel/Margin/TopRow/BackToMenuButton")
	_tap_hint_label = get_node("UI/TapHintLabel")
	_perfect_label = get_node("UI/PerfectLabel")
	_level_complete_label = get_node("UI/LevelCompleteLabel")
	_unlock_popup = get_node("UI/UnlockPopup")
	_unlock_popup_label = get_node("UI/UnlockPopup/Panel/Margin/Content/UnlockLabel")
	_unlock_popup_preview = get_node("UI/UnlockPopup/Panel/Margin/Content/UnlockPreview")
	_place_sound_player = get_node("PlaceSoundPlayer")
	_result_sound_player = get_node("ResultSoundPlayer")
	_sprinkle_particles = get_node("SprinkleParticles")

	_base_platform_start_position = _base_platform.global_position
	_spawn_base_y = _current_block_spawn.global_position.y
	_camera_start_position = _camera.position
	_camera_base_position = _camera_start_position
	_last_viewport_size = get_viewport_rect().size

	_restart_button.pressed.connect(_on_restart_pressed)
	_next_level_button.pressed.connect(_on_next_level_pressed)
	_back_to_menu_button.pressed.connect(_on_back_to_menu_pressed)

	AppSettings.ensure_loaded()
	GameProgress.ensure_loaded()
	CakeUnlockManager.ensure_loaded()
	_build_default_texture_list()

	_place_sound_player.stream = ToneFactory.create_cake_stack_sound()
	_result_sound_player.stream = ToneFactory.create_gentle_win_sound()
	_setup_decorative_sprites()
	_setup_background_decor()
	_configure_sprinkle_particles()
	_apply_responsive_ui(_last_viewport_size)
	_start_level()

func _process(delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size != _last_viewport_size:
		_last_viewport_size = viewport_size
		_apply_responsive_ui(viewport_size)

	if _camera_shake_time_left > 0.0:
		_camera_shake_time_left = maxf(0.0, _camera_shake_time_left - delta)
		var decay := _camera_shake_time_left / 0.12
		var offset := Vector2(
			_random.randf_range(-_camera_shake_strength, _camera_shake_strength),
			_random.randf_range(-_camera_shake_strength, _camera_shake_strength)
		) * decay
		_camera.position = _camera_base_position + offset
		if _camera_shake_time_left <= 0.0:
			_camera.position = _camera_base_position

	_update_background_visuals()

func _input(event: InputEvent) -> void:
	if not _game_active or _current_block == null:
		return

	var place_pressed := false
	var pointer_position := Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _should_ignore_mouse_placement_input():
			return
		place_pressed = true
		pointer_position = event.position
	elif event is InputEventScreenTouch and event.pressed:
		place_pressed = true
		pointer_position = event.position

	if not place_pressed or _is_pointer_over_button(pointer_position):
		return

	get_viewport().set_input_as_handled()
	_place_current_block()

func _start_level() -> void:
	for child in _placed_blocks_root.get_children():
		child.queue_free()

	_active_level_index = GameProgress.current_level_index
	_active_level = GameProgress.get_current_level()
	_game_mode = GameProgress.current_game_mode
	_unlocked_cake_variants = CakeUnlockManager.get_unlocked_variants()
	_current_block = null
	_placed_block_count = 0
	_game_active = true

	_base_platform.stop_movement()
	_base_platform.scale = Vector2.ONE
	_base_platform.modulate = Color.WHITE
	_base_platform.snap_to(_base_platform_start_position.x, _base_platform_start_position.y)
	_base_platform.set_height(block_height_step)
	_base_platform.set_width(_active_level.initial_block_width)
	_base_platform.set_block_texture(_get_block_texture(0))
	_base_platform.set_block_color(_get_block_color(0))
	_reference_block = _base_platform

	_camera.position = _camera_start_position
	_camera_base_position = _camera_start_position
	_camera_shake_time_left = 0.0
	_perfect_label.visible = false
	_perfect_label.scale = Vector2.ZERO
	_level_complete_label.visible = false
	_level_complete_label.scale = Vector2.ZERO
	_unlock_popup.visible = false
	_unlock_popup.scale = Vector2.ONE * 0.8
	_unlock_popup.modulate = Color(1, 1, 1, 0)
	_level_label.text = "Endless Mode" if _game_mode == GameMode.Type.ENDLESS else "Level %d" % (_active_level_index + 1)
	_status_label.modulate = Color.WHITE
	_status_label.text = "Line up the block"
	_tap_hint_label.visible = true
	_tap_hint_label.text = "Tap or click to stack"
	_restart_button.visible = false
	_restart_button.disabled = true
	_next_level_button.visible = false
	_next_level_button.disabled = true
	_back_to_menu_button.disabled = false

	_update_progress_label()
	_update_tower_decor()
	_reset_background_visuals()
	_spawn_next_block()

func _spawn_next_block() -> void:
	if block_scene == null:
		push_error("BlockScene is not assigned on GameController.")
		return

	var next_block = block_scene.instantiate()
	_placed_blocks_root.add_child(next_block)
	var spawn_y := _spawn_base_y - (_placed_block_count * block_height_step)
	next_block.snap_to(_current_block_spawn.global_position.x, spawn_y)
	next_block.set_height(block_height_step)
	next_block.set_width(_reference_block.width)
	next_block.set_block_texture(_get_block_texture(_placed_block_count + 1))
	next_block.set_block_color(_get_block_color(_placed_block_count + 1))
	next_block.start_movement(_current_block_spawn.global_position.x, _active_level.block_move_speed, _active_level.horizontal_move_range, _placed_block_count * 0.8)
	_current_block = next_block

func _place_current_block() -> void:
	var current_block: MovingBlock = _current_block
	_current_block = null
	_tap_hint_label.visible = false
	current_block.stop_movement()

	var previous_left: float = _reference_block.left_x
	var previous_right: float = _reference_block.right_x
	var current_left: float = current_block.left_x
	var current_right: float = current_block.right_x
	var overlap: float = minf(previous_right, current_right) - maxf(previous_left, current_left)

	if overlap < _active_level.min_valid_overlap:
		_create_falling_piece(current_block.width, current_block.center_x, current_block.global_position.y, current_block.block_texture, current_block.fill_color, 1.0 if current_block.center_x >= _reference_block.center_x else -1.0)
		current_block.queue_free()
		_end_level(false, "Missed the stack" if overlap <= 0.0 else "Overlap too small")
		return

	var overlap_left: float = maxf(previous_left, current_left)
	var overlap_right: float = minf(previous_right, current_right)
	var overlap_center: float = (overlap_left + overlap_right) * 0.5
	var cut_amount: float = current_block.width - overlap

	_create_trimmed_offcut(current_block, overlap_left, overlap_right)
	current_block.set_width(overlap)
	current_block.snap_to(overlap_center, current_block.global_position.y)
	_reference_block = current_block
	_placed_block_count += 1
	_place_sound_player.play()
	_play_placement_feedback(current_block, cut_amount)
	_update_progress_label()
	_update_camera()
	_update_tower_decor()

	if _game_mode == GameMode.Type.LEVEL and _placed_block_count >= _active_level.required_blocks_to_win:
		GameProgress.complete_current_level()
		var unlocked_variant := CakeUnlockManager.try_unlock_for_completed_level(_active_level_index + 1)
		_end_level(true, "Level cleared!" if GameProgress.has_next_level(_active_level_index) else "You finished every level!")
		if unlocked_variant != null:
			_show_unlock_popup(unlocked_variant)
		return

	_spawn_next_block()

func _create_trimmed_offcut(original_block: MovingBlock, overlap_left: float, overlap_right: float) -> void:
	var original_left: float = original_block.left_x
	var original_right: float = original_block.right_x
	var y: float = original_block.global_position.y
	var left_offcut_width: float = overlap_left - original_left
	if left_offcut_width > 0.5:
		_create_falling_piece(left_offcut_width, original_left + (left_offcut_width * 0.5), y, original_block.block_texture, original_block.fill_color, -1.0)
	var right_offcut_width: float = original_right - overlap_right
	if right_offcut_width > 0.5:
		_create_falling_piece(right_offcut_width, overlap_right + (right_offcut_width * 0.5), y, original_block.block_texture, original_block.fill_color, 1.0)

func _create_falling_piece(width_value: float, center_x_value: float, center_y: float, texture: Texture2D, color: Color, horizontal_direction: float) -> void:
	if block_scene == null:
		return
	var falling_piece = block_scene.instantiate()
	_placed_blocks_root.add_child(falling_piece)
	falling_piece.stop_movement()
	falling_piece.set_height(block_height_step)
	falling_piece.set_width(width_value)
	falling_piece.set_block_texture(texture)
	falling_piece.set_block_color(color.darkened(0.18))
	falling_piece.snap_to(center_x_value, center_y)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(falling_piece, "position", falling_piece.position + Vector2(cut_horizontal_drift * horizontal_direction, cut_fall_distance), cut_fall_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(falling_piece, "rotation_degrees", 34.0 * horizontal_direction, cut_fall_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(falling_piece, "modulate:a", 0.1, cut_fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(falling_piece.queue_free)

func _play_placement_feedback(placed_block: MovingBlock, cut_amount: float) -> void:
	var status_color := Color.WHITE
	var status_text := "Nice stack"
	var is_perfect := false
	if cut_amount <= perfect_placement_threshold:
		status_color = Color(0.96, 0.88, 0.34, 1.0)
		status_text = "Perfect!"
		is_perfect = true
	elif cut_amount <= near_perfect_placement_threshold:
		status_color = Color(0.66, 0.93, 0.82, 1.0)
		status_text = "Great placement"
	else:
		status_text = "Keep climbing"

	_status_label.text = status_text
	_status_label.modulate = status_color
	_tap_hint_label.visible = true
	_tap_hint_label.text = "Tap again for the next block"
	_play_tower_bounce()
	_emit_sprinkles(placed_block.global_position)
	_start_camera_shake(0.12, 4.0)
	if is_perfect:
		_play_perfect_label()

func _end_level(won: bool, status_text: String) -> void:
	_game_active = false
	_current_block = null
	if _game_mode == GameMode.Type.ENDLESS and not won:
		var is_new_record := GameProgress.try_set_best_endless_score(_placed_block_count)
		_status_label.text = "New best! Score %d" % _placed_block_count if is_new_record else "Endless score: %d\nBest: %d" % [_placed_block_count, GameProgress.best_endless_score]
	else:
		_status_label.text = status_text if won else "You lose! %s" % status_text

	_status_label.modulate = Color(0.78, 0.97, 0.76, 1.0) if won else Color(1.0, 0.68, 0.68, 1.0)
	_tap_hint_label.visible = false
	_result_sound_player.stream = ToneFactory.create_gentle_win_sound() if won else ToneFactory.create_gentle_lose_sound()
	_result_sound_player.play()
	_restart_button.visible = true
	_restart_button.disabled = false
	_restart_button.text = "Restart Endless" if _game_mode == GameMode.Type.ENDLESS else "Restart Level"

	var can_go_next := _game_mode == GameMode.Type.LEVEL and won and GameProgress.has_next_level(_active_level_index)
	_next_level_button.visible = can_go_next
	_next_level_button.disabled = not can_go_next
	if won:
		_play_level_complete_label()

func _update_progress_label() -> void:
	_progress_label.text = "Score %d  Best %d" % [_placed_block_count, GameProgress.best_endless_score] if _game_mode == GameMode.Type.ENDLESS else "Blocks %d/%d" % [_placed_block_count, _active_level.required_blocks_to_win]

func _update_camera() -> void:
	var viewport_size := get_viewport_rect().size
	var zoom_y := maxf(_camera.zoom.y, 0.01)
	var safe_screen_y := _status_panel.get_global_rect().end.y + camera_ui_safe_padding
	var tower_top_y := _get_highest_block_top_y()
	var required_camera_y := tower_top_y + ((viewport_size.y * 0.5) - safe_screen_y) / zoom_y
	_camera_base_position = Vector2(_camera_start_position.x, minf(_camera_start_position.y, required_camera_y))
	if _camera_shake_time_left <= 0.0:
		_camera.position = _camera_base_position

func _get_highest_block_top_y() -> float:
	var top_y: float = _reference_block.global_position.y - (block_height_step * 0.5)
	if _current_block != null:
		top_y = minf(top_y, _current_block.global_position.y - (block_height_step * 0.5))
	return top_y

func _get_block_color(index: int) -> Color:
	if _get_configured_block_texture_count() > 0:
		return Color.WHITE
	return _block_colors[index % _block_colors.size()]

func _get_block_texture(index: int) -> Texture2D:
	var variant := _get_variant_for_block_index(index)
	var textures := variant.get_block_textures(_default_block_textures)
	if textures.is_empty():
		return null
	return textures[index % textures.size()]

func _get_configured_block_texture_count() -> int:
	return _get_variant_for_block_index(_placed_block_count).get_block_textures(_default_block_textures).size()

func _play_tower_bounce() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_placed_blocks_root, "scale", Vector2(1.0, 0.92), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_base_platform, "scale", Vector2(1.0, 0.96), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_tower_shadow, "scale", Vector2(_tower_shadow.scale.x * 1.06, _tower_shadow.scale.y * 1.12), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().set_parallel(true)
	tween.tween_property(_placed_blocks_root, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_base_platform, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_tower_shadow, "scale", _get_tower_shadow_scale(), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _emit_sprinkles(world_position: Vector2) -> void:
	_sprinkle_particles.global_position = world_position + Vector2(0.0, -10.0)
	_sprinkle_particles.restart()
	_sprinkle_particles.emitting = true

func _start_camera_shake(duration: float, strength: float) -> void:
	_camera_shake_time_left = duration
	_camera_shake_strength = strength

func _play_perfect_label() -> void:
	_perfect_label.visible = true
	_perfect_label.scale = Vector2.ZERO
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_perfect_label, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(_perfect_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(_perfect_label, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void: _perfect_label.visible = false)

func _play_level_complete_label() -> void:
	_level_complete_label.visible = true
	_level_complete_label.scale = Vector2.ZERO
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_level_complete_label, "scale", Vector2(1.2, 1.2), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(_level_complete_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(_level_complete_label, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void: _level_complete_label.visible = false)

func _on_restart_pressed() -> void:
	if _game_mode == GameMode.Type.ENDLESS:
		GameProgress.start_endless_mode()
	_start_level()

func _on_next_level_pressed() -> void:
	if _game_mode != GameMode.Type.LEVEL:
		return
	if not GameProgress.advance_to_next_level():
		return
	_start_level()

func _on_back_to_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _is_pointer_over_button(screen_position: Vector2) -> bool:
	return _is_pointer_over_control(_back_to_menu_button, screen_position) or _is_pointer_over_control(_restart_button, screen_position) or _is_pointer_over_control(_next_level_button, screen_position)

func _is_pointer_over_control(control: Button, screen_position: Vector2) -> bool:
	return control.visible and not control.disabled and control.get_global_rect().has_point(screen_position)

func _build_default_texture_list() -> void:
	_default_block_textures.clear()
	for texture in [block_texture1, block_texture2, block_texture3, block_texture4]:
		if texture != null:
			_default_block_textures.append(texture)

func _get_variant_for_block_index(block_index: int) -> CakeVariantConfig:
	if _unlocked_cake_variants.is_empty():
		_unlocked_cake_variants = CakeUnlockManager.get_unlocked_variants()
	return _unlocked_cake_variants[block_index % _unlocked_cake_variants.size()]

func _should_ignore_mouse_placement_input() -> bool:
	return OS.has_feature("mobile") or (ProjectSettings.has_setting("input_devices/pointing/emulate_touch_from_mouse") and bool(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse")))

func _setup_decorative_sprites() -> void:
	_cake_plate.texture = _create_cake_plate_texture(360, 118)
	_cake_plate_shadow.texture = _create_soft_ellipse_texture(320, 78, Color(0.29, 0.16, 0.22, 0.2))
	_tower_shadow.texture = _create_soft_ellipse_texture(260, 70, Color(0.29, 0.16, 0.22, 0.15))
	_tower_shadow.visible = false

func _setup_background_decor() -> void:
	var cloud_left: Polygon2D = get_node("CloudLeft")
	var cloud_right: Polygon2D = get_node("CloudRight")
	_clouds = [cloud_left, cloud_right]
	_cloud_base_offsets = [cloud_left.position, cloud_right.position]
	_cloud_drift_speeds = [8.0, -10.0]
	for i in range(4):
		var cloud := _create_cloud_polygon(0.28 if i % 2 == 0 else 0.22)
		add_child(cloud)
		move_child(cloud, 4 + i)
		_clouds.append(cloud)
		_cloud_base_offsets.append(Vector2(-240.0 if i % 2 == 0 else 230.0, -260.0 - (i * 170.0)))
		_cloud_drift_speeds.append(_random.randf_range(-14.0, 14.0))

func _configure_sprinkle_particles() -> void:
	_sprinkle_particles.texture = _create_sprinkle_texture(12, 4)
	_sprinkle_particles.amount = 18
	_sprinkle_particles.lifetime = 0.7
	_sprinkle_particles.one_shot = true
	_sprinkle_particles.explosiveness = 1.0
	_sprinkle_particles.direction = Vector2.DOWN
	_sprinkle_particles.spread = 40.0
	_sprinkle_particles.gravity = Vector2(0.0, 420.0)
	_sprinkle_particles.initial_velocity_min = 70.0
	_sprinkle_particles.initial_velocity_max = 120.0
	_sprinkle_particles.scale_amount_min = 0.85
	_sprinkle_particles.scale_amount_max = 1.25
	_sprinkle_particles.color_ramp = _create_sprinkle_gradient()

func _update_tower_decor() -> void:
	_cake_plate.global_position = _base_platform.global_position + Vector2(0.0, block_height_step * 0.66)
	_cake_plate_shadow.global_position = _cake_plate.global_position + Vector2(0.0, 24.0)
	_cake_plate.scale = Vector2(maxf((_active_level.initial_block_width + 130.0) / 360.0, 1.15), 1.08)
	_cake_plate_shadow.scale = Vector2(_cake_plate.scale.x * 1.1, 0.34)
	_tower_shadow.global_position = _base_platform.global_position + Vector2(0.0, block_height_step * 0.92)
	_tower_shadow.scale = _get_tower_shadow_scale()

func _reset_background_visuals() -> void:
	_highest_cloud_anchor_y = _camera_base_position.y
	for i in range(_clouds.size()):
		var base_offset := _cloud_base_offsets[i]
		_clouds[i].position = Vector2(base_offset.x, _camera_base_position.y + base_offset.y)
	_update_background_visuals()

func _update_background_visuals() -> void:
	var viewport_size := get_viewport_rect().size
	var zoom_x := maxf(_camera.zoom.x, 0.01)
	var zoom_y := maxf(_camera.zoom.y, 0.01)
	var visible_world_width := viewport_size.x / zoom_x
	var visible_world_height := viewport_size.y / zoom_y
	var half_width := maxf((visible_world_width * 0.5) + 140.0, 520.0)
	var top_height := maxf(visible_world_height * 0.72, 820.0)
	var bottom_height := maxf(visible_world_height * 1.05, 980.0)
	var camera_y := _camera.position.y
	_backdrop_top.position = Vector2(-half_width, camera_y - top_height)
	_backdrop_top.size = Vector2(half_width * 2.0, top_height + 420.0)
	_backdrop_bottom.position = Vector2(-half_width, camera_y - 40.0)
	_backdrop_bottom.size = Vector2(half_width * 2.0, bottom_height)

	for i in range(_clouds.size()):
		var drifted_base := _cloud_base_offsets[i]
		drifted_base.x += _cloud_drift_speeds[i] * get_process_delta_time()
		var horizontal_limit := half_width + 180.0
		if drifted_base.x > horizontal_limit:
			drifted_base.x = -horizontal_limit
		elif drifted_base.x < -horizontal_limit:
			drifted_base.x = horizontal_limit
		_cloud_base_offsets[i] = drifted_base
		var target_y := (camera_y * (0.35 + (i * 0.04))) + drifted_base.y
		if target_y > camera_y + 120.0:
			_cloud_base_offsets[i] = Vector2(_random.randf_range(-300.0, 300.0), _highest_cloud_anchor_y - _random.randf_range(180.0, 320.0))
			_cloud_drift_speeds[i] = _random.randf_range(-14.0, 14.0)
			_highest_cloud_anchor_y = _cloud_base_offsets[i].y
			_clouds[i].position = _cloud_base_offsets[i]
			_clouds[i].rotation = _random.randf_range(-0.16, 0.16)
			_clouds[i].scale = Vector2.ONE * _random.randf_range(0.9, 1.15)
			continue
		_clouds[i].position = Vector2(_cloud_base_offsets[i].x, target_y)

func _get_tower_shadow_scale() -> Vector2:
	return Vector2(maxf((_active_level.initial_block_width + (_placed_block_count * 6.0)) / 260.0, 0.9), 0.34)

func _apply_responsive_ui(viewport_size: Vector2) -> void:
	var compact := viewport_size.x < 550.0
	var ultra_compact := viewport_size.x < 430.0
	_top_panel.anchor_left = 0.03 if compact else 0.04
	_top_panel.anchor_right = 0.97 if compact else 0.96
	_top_panel.anchor_top = 0.03
	_top_panel.anchor_bottom = 0.205 if compact else 0.16
	_status_panel.anchor_left = 0.05 if compact else 0.08
	_status_panel.anchor_right = 0.95 if compact else 0.92
	_status_panel.anchor_top = 0.255 if compact else 0.18
	_status_panel.anchor_bottom = 0.35 if compact else 0.26
	_action_buttons.anchor_left = 0.05 if compact else 0.08
	_action_buttons.anchor_right = 0.95 if compact else 0.92
	_top_panel_margin.add_theme_constant_override("margin_left", 12 if compact else 18)
	_top_panel_margin.add_theme_constant_override("margin_top", 12 if compact else 16)
	_top_panel_margin.add_theme_constant_override("margin_right", 12 if compact else 18)
	_top_panel_margin.add_theme_constant_override("margin_bottom", 12 if compact else 16)
	_top_row.add_theme_constant_override("separation", 8 if compact else 12)
	_action_buttons.add_theme_constant_override("separation", 10 if compact else 16)
	_level_label.add_theme_font_size_override("font_size", 18 if ultra_compact else 20 if compact else 24)
	_progress_label.add_theme_font_size_override("font_size", 15 if ultra_compact else 17 if compact else 20)
	_status_label.add_theme_font_size_override("font_size", 18 if ultra_compact else 20 if compact else 22)
	_tap_hint_label.add_theme_font_size_override("font_size", 16 if ultra_compact else 18 if compact else 20)
	_perfect_label.add_theme_font_size_override("font_size", 42 if ultra_compact else 46 if compact else 52)
	_level_complete_label.add_theme_font_size_override("font_size", 48 if ultra_compact else 54 if compact else 62)
	_back_to_menu_button.custom_minimum_size = Vector2(118.0 if ultra_compact else 132.0 if compact else 170.0, 48.0 if compact else 56.0)
	_back_to_menu_button.add_theme_font_size_override("font_size", 14 if ultra_compact else 16 if compact else 20)
	_restart_button.custom_minimum_size = Vector2(0.0, 58.0 if compact else 64.0)
	_next_level_button.custom_minimum_size = Vector2(0.0, 58.0 if compact else 64.0)
	_restart_button.add_theme_font_size_override("font_size", 18 if ultra_compact else 20 if compact else 22)
	_next_level_button.add_theme_font_size_override("font_size", 18 if ultra_compact else 20 if compact else 22)
	_perfect_label.offset_left = 120.0 if compact else 250.0
	_perfect_label.offset_right = viewport_size.x - 120.0 if compact else 470.0
	_level_complete_label.offset_left = 36.0 if compact else 180.0
	_level_complete_label.offset_right = viewport_size.x - 36.0 if compact else 540.0
	_position_unlock_popup(viewport_size, compact)

func _show_unlock_popup(unlocked_variant: CakeVariantConfig) -> void:
	_unlock_popup_label.text = "New Cake Style Unlocked!\n%s" % unlocked_variant.display_name
	_unlock_popup_preview.texture = unlocked_variant.get_preview_texture(_default_block_textures)
	_position_unlock_popup(_last_viewport_size, _last_viewport_size.x < 550.0)
	_unlock_popup.visible = true
	_unlock_popup.scale = Vector2.ONE * 0.8
	_unlock_popup.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_unlock_popup, "scale", Vector2(1.05, 1.05), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_unlock_popup, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(_unlock_popup, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(1.6)
	tween.chain().tween_property(_unlock_popup, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void: _unlock_popup.visible = false)

func _position_unlock_popup(viewport_size: Vector2, compact: bool) -> void:
	var popup_width := minf((viewport_size.x - 48.0) if compact else 320.0, viewport_size.x - 32.0)
	var popup_height := 150.0 if compact else 184.0
	var popup_left := (viewport_size.x - popup_width) * 0.5
	var popup_top := maxf(24.0, _action_buttons.get_global_rect().position.y - popup_height - 18.0)
	_unlock_popup.anchor_left = 0.0
	_unlock_popup.anchor_top = 0.0
	_unlock_popup.anchor_right = 0.0
	_unlock_popup.anchor_bottom = 0.0
	_unlock_popup.offset_left = popup_left
	_unlock_popup.offset_top = popup_top
	_unlock_popup.offset_right = popup_left + popup_width
	_unlock_popup.offset_bottom = popup_top + popup_height

func _create_soft_ellipse_texture(width_value: int, height_value: int, color: Color) -> Texture2D:
	var image := Image.create_empty(width_value, height_value, false, Image.FORMAT_RGBA8)
	var center := Vector2((width_value - 1) * 0.5, (height_value - 1) * 0.5)
	var rx := width_value * 0.5
	var ry := height_value * 0.5
	for y in range(height_value):
		for x in range(width_value):
			var dx := (x - center.x) / rx
			var dy := (y - center.y) / ry
			var distance := sqrt((dx * dx) + (dy * dy))
			if distance > 1.0:
				image.set_pixel(x, y, Color.TRANSPARENT)
			else:
				image.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * clampf((1.0 - distance) / 0.35, 0.0, 1.0)))
	return ImageTexture.create_from_image(image)

func _create_cake_plate_texture(width_value: int, height_value: int) -> Texture2D:
	var image := Image.create_empty(width_value, height_value, false, Image.FORMAT_RGBA8)
	_draw_filled_ellipse(image, Rect2(24, 26, width_value - 48, 18), Color(0.84, 0.73, 0.79, 0.45))
	_draw_rounded_rect(image, Rect2((width_value * 0.5) - 34.0, 48.0, 68.0, 28.0), 12, Color(0.86, 0.74, 0.80, 0.95))
	_draw_filled_ellipse(image, Rect2((width_value * 0.5) - 68.0, 68.0, 136.0, 24.0), Color(0.86, 0.74, 0.80, 0.95).darkened(0.08))
	return ImageTexture.create_from_image(image)

func _create_sprinkle_texture(width_value: int, height_value: int) -> Texture2D:
	var image := Image.create_empty(width_value, height_value, false, Image.FORMAT_RGBA8)
	_draw_rounded_rect(image, Rect2(0, 0, width_value, height_value), 2, Color.WHITE)
	return ImageTexture.create_from_image(image)

func _create_sprinkle_gradient() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	gradient.colors = PackedColorArray([Color("FFD166"), Color("FF8FAB"), Color("7BDFF2"), Color("F4A261")])
	return gradient

func _create_cloud_polygon(alpha: float) -> Polygon2D:
	var cloud := Polygon2D.new()
	cloud.color = Color(1, 1, 1, alpha)
	cloud.polygon = PackedVector2Array([Vector2(-120, 4), Vector2(-80, -30), Vector2(-24, -20), Vector2(10, -54), Vector2(86, -18), Vector2(130, 4), Vector2(88, 24), Vector2(-94, 28)])
	return cloud

func _draw_filled_ellipse(image: Image, rect: Rect2, color: Color) -> void:
	var center := rect.position + (rect.size * 0.5)
	var rx := rect.size.x * 0.5
	var ry := rect.size.y * 0.5
	for y in range(floori(rect.position.y), ceili(rect.end.y)):
		for x in range(floori(rect.position.x), ceili(rect.end.x)):
			var dx := (x - center.x) / rx
			var dy := (y - center.y) / ry
			if (dx * dx) + (dy * dy) <= 1.0:
				image.set_pixel(x, y, color)

func _draw_rounded_rect(image: Image, rect: Rect2, radius: int, color: Color) -> void:
	for y in range(floori(rect.position.y), ceili(rect.end.y)):
		for x in range(floori(rect.position.x), ceili(rect.end.x)):
			var local_x: float = x - rect.position.x
			var local_y: float = y - rect.position.y
			var inside_core := (local_x >= radius and local_x <= rect.size.x - radius) or (local_y >= radius and local_y <= rect.size.y - radius)
			if inside_core:
				image.set_pixel(x, y, color)
				continue
			var corner_x: float = radius if local_x < radius else rect.size.x - radius
			var corner_y: float = radius if local_y < radius else rect.size.y - radius
			var dx: float = local_x - corner_x
			var dy: float = local_y - corner_y
			if (dx * dx) + (dy * dy) <= radius * radius:
				image.set_pixel(x, y, color)
