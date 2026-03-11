extends Node2D

@export var level_catalog: PrototypeLevelCatalog
@export var starting_level_index: int = 0

@onready var spawner: CakeSpawner = $Spawner
@onready var knife: KnifeController = $Knife
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hud_panel: Control = $UI/HudPanel
@onready var hint_label: Label = $UI/Hint
@onready var hud_row: HBoxContainer = $UI/HudPanel/Margin/HudRow
@onready var stats_row: HBoxContainer = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow
@onready var floating_result_label: Label = $UI/FloatingResultLabel
@onready var level_badge: Control = $UI/HudPanel/Margin/HudRow/LevelBadge
@onready var stats_bar: Control = $UI/HudPanel/Margin/HudRow/StatsBar
@onready var level_title_label: Label = $UI/HudPanel/Margin/HudRow/LevelBadge/LevelValue
@onready var cake_icon_bg: Control = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/CakeIconBg
@onready var cake_icon: TextureRect = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/CakeIconBg/CakeIcon
@onready var divider_a: ColorRect = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/DividerA
@onready var divider_b: ColorRect = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/DividerB
@onready var cakes_value_label: Label = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/CakesValue
@onready var miss_icon_bg: Control = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/MissIconBg
@onready var miss_icon: Label = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/MissIconBg/MissIcon
@onready var misses_value_label: Label = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/MissesValue
@onready var speed_icon_bg: Control = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/SpeedIconBg
@onready var speed_icon: Label = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/SpeedIconBg/SpeedIcon
@onready var speed_value_label: Label = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/SpeedValue
@onready var menu_button: TextureButton = $UI/HudPanel/Margin/HudRow/StatsBar/StatsMargin/StatsRow/MenuButton
@onready var shift_summary_overlay: Control = $UI/ShiftSummaryOverlay
@onready var summary_level_label: Label = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/LevelLabel
@onready var summary_perfect_label: Label = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/Stats/PerfectLabel
@onready var summary_good_label: Label = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/Stats/GoodLabel
@onready var summary_miss_label: Label = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/Stats/MissLabel
@onready var summary_score_label: Label = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/ScoreLabel
@onready var summary_rating_label: Label = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/RatingLabel
@onready var summary_unlock_reward: Control = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/UnlockReward
@onready var summary_unlock_label: Label = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/UnlockReward/Margin/Row/Text/UnlockLabel
@onready var summary_unlock_name_label: Label = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/UnlockReward/Margin/Row/Text/UnlockNameLabel
@onready var summary_unlock_preview_frame: Control = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/UnlockReward/Margin/Row/PreviewFrame
@onready var summary_unlock_preview: TextureRect = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/UnlockReward/Margin/Row/PreviewFrame/Preview
@onready var summary_unlock_ribbon: Control = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/UnlockReward/Margin/Row/PreviewFrame/NewRibbon
@onready var continue_label: Label = $UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/ContinueLabel
@onready var star_nodes: Array[PanelContainer] = [
	$UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/Stars/Star1,
	$UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/Stars/Star2,
	$UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/Stars/Star3
]
@onready var star_glyph_nodes: Array[Label] = [
	$UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/Stars/Star1/Glyph,
	$UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/Stars/Star2/Glyph,
	$UI/ShiftSummaryOverlay/ShiftSummaryPanel/Margin/Content/Stars/Star3/Glyph
]
@onready var belt_segments: Array[ColorRect] = [
	$Conveyor/BeltStripeA,
	$Conveyor/BeltStripeB,
	$Conveyor/BeltStripeC,
	$Conveyor/BeltStripeD,
	$Conveyor/BeltStripeE
]

const PERFECT_POINTS: int = 100
const GOOD_POINTS: int = 60
const MISS_POINTS: int = -40
const BELT_WRAP_LEFT: float = -460.0
const BELT_SEGMENT_SPACING: float = 220.0

var _current_level_index: int = 0
var _current_level: PrototypeLevelConfig
var _cakes_spawned: int = 0
var _cakes_resolved: int = 0
var _misses_used: int = 0
var _perfect_count: int = 0
var _good_count: int = 0
var _miss_count: int = 0
var _level_active: bool = false
var _awaiting_continue: bool = false
var _last_level_won: bool = false
var _input_locked: bool = false
var _floating_result_tween: Tween
var _last_unlocked_variant: CakeVariantConfig

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	knife.cut_resolved.connect(_on_cut_resolved)
	menu_button.pressed.connect(_on_menu_button_pressed)
	shift_summary_overlay.visible = false
	floating_result_label.visible = false
	GameProgress.ensure_loaded()
	CakeUnlockManager.ensure_loaded()
	if level_catalog == null:
		level_catalog = PrototypeLevelCatalog.new()
	_apply_responsive_hud()
	_start_level(clampi(GameProgress.prototype_current_level_index, 0, level_catalog.get_level_count() - 1))

func _process(delta: float) -> void:
	var belt_scroll_speed: float = 92.0
	for segment in belt_segments:
		segment.position.x -= belt_scroll_speed * delta
		if segment.position.x < BELT_WRAP_LEFT:
			segment.position.x += BELT_SEGMENT_SPACING * belt_segments.size()

func _input(event: InputEvent) -> void:
	if _input_locked:
		get_viewport().set_input_as_handled()
		return

	if not _is_tap_input(event):
		return

	if _is_event_over_control(event, menu_button):
		return

	if _awaiting_continue:
		_input_locked = true
		get_viewport().set_input_as_handled()
		if _last_level_won:
			call_deferred("_start_level_after_continue", _current_level_index + 1 if _current_level_index + 1 < _get_level_count() else 0)
		else:
			call_deferred("_start_level_after_continue", _current_level_index)
		return

	if shift_summary_overlay.visible or not _level_active:
		get_viewport().set_input_as_handled()
		return

	if _level_active:
		knife.try_drop()
		get_viewport().set_input_as_handled()

func _on_spawn_timer_timeout() -> void:
	_spawn_next_cake()

func _on_cut_resolved(result: String, _distance: float, world_position: Vector2, resolved_cake: bool) -> void:
	match result:
		"Perfect":
			_perfect_count += 1
			_cakes_resolved += 1
			_show_floating_result("PERFECT", Color(0.95, 0.85, 0.25, 1.0), world_position)
		"Good":
			_good_count += 1
			_cakes_resolved += 1
			_show_floating_result("GOOD", Color(0.4, 0.9, 0.55, 1.0), world_position)
		_:
			_miss_count += 1
			_misses_used += 1
			if resolved_cake:
				_cakes_resolved += 1
			_show_floating_result("MISS", Color(1.0, 0.45, 0.45, 1.0), world_position)

	_update_level_info()
	_check_level_end()

func _start_level(level_index: int) -> void:
	if level_catalog == null:
		level_catalog = PrototypeLevelCatalog.new()

	for node in get_tree().get_nodes_in_group("cakes"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("cake_pieces"):
		node.queue_free()

	_current_level_index = clampi(level_index, 0, level_catalog.get_level_count() - 1)
	_current_level = level_catalog.get_level(_current_level_index)
	_cakes_spawned = 0
	_cakes_resolved = 0
	_misses_used = 0
	_perfect_count = 0
	_good_count = 0
	_miss_count = 0
	_level_active = true
	_awaiting_continue = false
	_last_level_won = false
	_last_unlocked_variant = null
	shift_summary_overlay.visible = false
	floating_result_label.visible = false
	spawner.reset_cake_cycle()
	_update_level_info()
	spawn_timer.stop()
	_spawn_next_cake()

func _spawn_next_cake() -> void:
	if not _level_active or _current_level == null:
		return

	if _cakes_spawned >= _current_level.cake_count:
		spawn_timer.stop()
		_check_level_end()
		return

	var cake: MovingCake = spawner.spawn_cake(_current_level)
	if cake != null:
		cake.exited_uncut.connect(_on_cake_exited_uncut)
		_cakes_spawned += 1

	if _cakes_spawned < _current_level.cake_count:
		spawn_timer.wait_time = spawner.get_spawn_delay(_current_level)
		spawn_timer.start()
	else:
		spawn_timer.stop()

	_update_level_info()

func _on_cake_exited_uncut() -> void:
	if not _level_active:
		return

	_cakes_resolved += 1
	_misses_used += 1
	_miss_count += 1
	_show_floating_result("ESCAPED", Color(1.0, 0.45, 0.45, 1.0), Vector2(knife.global_position.x + 180.0, 420.0))
	_update_level_info()
	_check_level_end()

func _check_level_end() -> void:
	if not _level_active or _current_level == null:
		return

	if _misses_used > _current_level.allowed_misses:
		_level_active = false
		_awaiting_continue = true
		_last_level_won = false
		_last_unlocked_variant = null
		spawn_timer.stop()
		_show_shift_summary()
		_update_level_info()
		return

	if _cakes_resolved >= _current_level.cake_count:
		_level_active = false
		_awaiting_continue = true
		_last_level_won = true
		GameProgress.prototype_current_level_index = _current_level_index
		GameProgress.complete_prototype_level(_get_level_count())
		_last_unlocked_variant = CakeUnlockManager.try_unlock_for_completed_level(_current_level.level_number)
		spawn_timer.stop()
		_show_shift_summary()
		_update_level_info()

func _update_level_info() -> void:
	if _current_level == null:
		level_title_label.text = "LEVEL 0"
		cakes_value_label.text = "0/0"
		misses_value_label.text = "0/0"
		speed_value_label.text = "0"
		return

	level_title_label.text = "LEVEL %d" % _current_level.level_number
	cakes_value_label.text = "%d/%d" % [_cakes_resolved, _current_level.cake_count]
	misses_value_label.text = "%d/%d" % [_misses_used, _current_level.allowed_misses]
	speed_value_label.text = "%.0f" % _current_level.conveyor_speed

func _calculate_final_score() -> int:
	return (_perfect_count * PERFECT_POINTS) + (_good_count * GOOD_POINTS) + (_miss_count * MISS_POINTS)

func _calculate_star_rating() -> int:
	var max_score: float = maxf(float(_current_level.cake_count * PERFECT_POINTS), 1.0)
	var score_ratio: float = float(_calculate_final_score()) / max_score
	if score_ratio >= 0.85 and _miss_count <= max(1, _current_level.allowed_misses / 2):
		return 3
	if score_ratio >= 0.55:
		return 2
	if score_ratio >= 0.25:
		return 1
	return 0

func _show_shift_summary() -> void:
	var final_score: int = _calculate_final_score()
	var stars: int = _calculate_star_rating()

	shift_summary_overlay.visible = true
	summary_level_label.text = "Shift %d Results" % _current_level.level_number
	summary_perfect_label.text = "Perfect: %d" % _perfect_count
	summary_good_label.text = "Good: %d" % _good_count
	summary_miss_label.text = "Miss: %d" % _miss_count
	summary_score_label.text = "Final Score: %d" % final_score
	summary_rating_label.text = "%s %d / 3" % [_filled_star_symbol(), stars]
	if _last_unlocked_variant != null:
		summary_unlock_reward.visible = true
		summary_unlock_label.text = "New cake unlocked!"
		summary_unlock_name_label.text = _last_unlocked_variant.display_name
		summary_unlock_preview.texture = _last_unlocked_variant.get_preview_texture([])
		summary_unlock_preview_frame.scale = Vector2(0.74, 0.74)
		summary_unlock_preview_frame.rotation = -0.08
		summary_unlock_ribbon.scale = Vector2(0.72, 0.72)
		summary_unlock_ribbon.modulate.a = 0.0
	else:
		summary_unlock_reward.visible = false
		summary_unlock_label.text = ""
		summary_unlock_name_label.text = ""
		summary_unlock_preview.texture = null
	continue_label.text = "Tap to continue" if _last_level_won else "Tap to retry"

	for star_index in range(star_nodes.size()):
		var star: PanelContainer = star_nodes[star_index]
		var glyph: Label = star_glyph_nodes[star_index]
		star.visible = true
		star.scale = Vector2.ZERO
		star.position.y = 14.0
		glyph.text = _filled_star_symbol()
		if star_index < stars:
			star.modulate = Color(1.0, 1.0, 1.0, 0.0)
			glyph.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			star.modulate = Color(1.0, 1.0, 1.0, 0.3)
			glyph.modulate = Color(1.0, 1.0, 1.0, 0.38)
			star.scale = Vector2(0.9, 0.9)
			star.position.y = 0.0

	for star_index in range(stars):
		var star: PanelContainer = star_nodes[star_index]
		var tween: Tween = create_tween()
		tween.tween_interval(0.18 * star_index)
		tween.tween_property(star, "modulate:a", 1.0, 0.01)
		tween.parallel().tween_property(star, "scale", Vector2(1.34, 1.34), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(star, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(star, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	if _last_unlocked_variant != null:
		var unlock_tween: Tween = create_tween()
		unlock_tween.tween_interval(0.26)
		unlock_tween.tween_property(summary_unlock_preview_frame, "scale", Vector2(1.12, 1.12), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		unlock_tween.parallel().tween_property(summary_unlock_preview_frame, "rotation", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		unlock_tween.parallel().tween_property(summary_unlock_ribbon, "modulate:a", 1.0, 0.12)
		unlock_tween.parallel().tween_property(summary_unlock_ribbon, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		unlock_tween.tween_property(summary_unlock_preview_frame, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _filled_star_symbol() -> String:
	return char(0x1F31F)

func _get_level_count() -> int:
	return 0 if level_catalog == null else level_catalog.get_level_count()

func _is_tap_input(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept"):
		return true
	if event is InputEventScreenTouch and event.pressed:
		return true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		return true
	return false

func _start_level_after_continue(level_index: int) -> void:
	_start_level(level_index)
	await get_tree().process_frame
	_input_locked = false

func _show_floating_result(text: String, color: Color, world_position: Vector2) -> void:
	if _floating_result_tween != null and _floating_result_tween.is_valid():
		_floating_result_tween.kill()

	var screen_position: Vector2 = get_viewport().get_canvas_transform() * world_position
	floating_result_label.text = text
	floating_result_label.modulate = color
	floating_result_label.modulate.a = 1.0
	floating_result_label.scale = Vector2(0.72, 0.72)
	floating_result_label.position = screen_position + Vector2(-56.0, -132.0)
	floating_result_label.visible = true

	_floating_result_tween = create_tween()
	_floating_result_tween.tween_property(floating_result_label, "position", floating_result_label.position + Vector2(0.0, -42.0), 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_floating_result_tween.parallel().tween_property(floating_result_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_floating_result_tween.parallel().tween_property(floating_result_label, "modulate:a", 0.0, 0.22).set_delay(0.34)
	_floating_result_tween.finished.connect(_hide_floating_result)

func _hide_floating_result() -> void:
	floating_result_label.visible = false

func _on_menu_button_pressed() -> void:
	_input_locked = true
	_level_active = false
	_awaiting_continue = false
	spawn_timer.stop()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_apply_responsive_hud()

func _is_event_over_control(event: InputEvent, control: Control) -> bool:
	if control == null or not control.visible:
		return false

	var pointer_position: Vector2
	if event is InputEventMouseButton:
		pointer_position = event.position
	elif event is InputEventScreenTouch:
		pointer_position = event.position
	else:
		return false

	return control.get_global_rect().has_point(pointer_position)

func _apply_responsive_hud() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact_scale: float = clampf(viewport_size.x / 720.0, 0.52, 1.0)
	var side_padding: float = clampf(viewport_size.x * 0.02, 6.0, 18.0)
	var top_padding: float = clampf(viewport_size.y * 0.03, 18.0, 30.0)
	var hud_height: float = maxf(58.0, 72.0 * compact_scale)
	var row_separation: int = int(round(10.0 * compact_scale))
	var available_width: float = maxf(220.0, viewport_size.x - side_padding * 2.0)
	var level_width: float = clampf(available_width * 0.28, 84.0, 188.0)
	var stats_width: float = maxf(available_width - level_width - row_separation, 120.0)

	hud_panel.anchor_left = 0.0
	hud_panel.anchor_top = 0.0
	hud_panel.anchor_right = 1.0
	hud_panel.anchor_bottom = 0.0
	hud_panel.offset_left = side_padding
	hud_panel.offset_top = top_padding
	hud_panel.offset_right = -side_padding
	hud_panel.offset_bottom = top_padding + hud_height
	hud_panel.scale = Vector2.ONE
	hud_panel.pivot_offset = Vector2.ZERO

	hint_label.anchor_left = 0.03
	hint_label.anchor_top = 0.0
	hint_label.anchor_right = 0.97
	hint_label.anchor_bottom = 0.0
	hint_label.offset_left = 0.0
	hint_label.offset_top = top_padding + hud_height + 18.0
	hint_label.offset_right = 0.0
	hint_label.offset_bottom = top_padding + hud_height + 60.0
	hint_label.scale = Vector2.ONE
	hint_label.pivot_offset = Vector2.ZERO

	hud_row.add_theme_constant_override("separation", row_separation)
	stats_row.add_theme_constant_override("separation", max(6, int(round(10.0 * compact_scale))))

	level_badge.custom_minimum_size = Vector2(level_width, hud_height)
	stats_bar.custom_minimum_size = Vector2(stats_width, hud_height)
	cake_icon_bg.custom_minimum_size = Vector2(32.0 * compact_scale, 32.0 * compact_scale)
	cake_icon.custom_minimum_size = Vector2(24.0 * compact_scale, 24.0 * compact_scale)
	miss_icon_bg.custom_minimum_size = Vector2(32.0 * compact_scale, 32.0 * compact_scale)
	speed_icon_bg.custom_minimum_size = Vector2(32.0 * compact_scale, 32.0 * compact_scale)
	menu_button.custom_minimum_size = Vector2(32.0 * compact_scale, 32.0 * compact_scale)
	divider_a.custom_minimum_size = Vector2(2.0, 26.0 * compact_scale)
	divider_b.custom_minimum_size = Vector2(2.0, 26.0 * compact_scale)

	level_title_label.add_theme_font_size_override("font_size", max(16, int(round(24.0 * compact_scale))))
	cakes_value_label.add_theme_font_size_override("font_size", max(14, int(round(22.0 * compact_scale))))
	misses_value_label.add_theme_font_size_override("font_size", max(14, int(round(22.0 * compact_scale))))
	speed_value_label.add_theme_font_size_override("font_size", max(14, int(round(22.0 * compact_scale))))
	miss_icon.add_theme_font_size_override("font_size", max(14, int(round(22.0 * compact_scale))))
	speed_icon.add_theme_font_size_override("font_size", max(10, int(round(12.0 * compact_scale))))
	hint_label.add_theme_font_size_override("font_size", max(14, int(round(20.0 * compact_scale))))
