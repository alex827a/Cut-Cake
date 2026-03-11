extends Control

const PROTOTYPE_LEVELS_PATH := "res://PrototypeLevels.tres"

var _subtitle_label: Label
var _menu_buttons: VBoxContainer
var _last_viewport_size := Vector2.ZERO
var _play_button: Button
var _start_game_button: Button
var _settings_button: Button
var _level_select_button: Button
var _endless_mode_button: Button
var _privacy_policy_button: Button
var _quit_button: Button
var _ui_sound_player: AudioStreamPlayer
var _settings_overlay: Control
var _sound_toggle: CheckButton
var _volume_label: Label
var _volume_slider: HSlider
var _reset_cake_styles_button: Button
var _settings_back_button: Button
var _privacy_overlay: Control
var _privacy_panel: PanelContainer
var _privacy_margin: MarginContainer
var _privacy_title_label: Label
var _privacy_body_scroll: ScrollContainer
var _privacy_body_label: Label
var _privacy_back_button: Button
var _level_select_overlay: Control
var _level_select_panel: PanelContainer
var _level_select_margin: MarginContainer
var _level_select_title_label: Label
var _level_grid_scroll: ScrollContainer
var _level_grid: GridContainer
var _level_select_back_button: Button
var _level_buttons: Array[Button] = []
var _prototype_level_catalog: PrototypeLevelCatalog
var _prototype_level_count: int = 15

func _ready() -> void:
	_subtitle_label = get_node("MenuPanel/Margin/Content/SubtitleLabel")
	_menu_buttons = get_node("MenuPanel/Margin/Content/MenuButtons")
	_play_button = get_node("MenuPanel/Margin/Content/MenuButtons/PlayButton")
	_start_game_button = get_node("MenuPanel/Margin/Content/UtilityButtons/StartGameButton")
	_settings_button = get_node("MenuPanel/Margin/Content/UtilityButtons/SettingsButton")
	_level_select_button = get_node("MenuPanel/Margin/Content/MenuButtons/LevelSelectButton")
	_endless_mode_button = get_node("MenuPanel/Margin/Content/MenuButtons/EndlessModeButton")
	_privacy_policy_button = get_node("MenuPanel/Margin/Content/UtilityButtons/PrivacyPolicyButton")
	_quit_button = get_node("MenuPanel/Margin/Content/UtilityButtons/QuitButton")
	_ui_sound_player = get_node("UiSoundPlayer")
	_settings_overlay = get_node("SettingsOverlay")
	_sound_toggle = get_node("SettingsOverlay/SettingsPanel/Margin/Content/SoundToggle")
	_volume_label = get_node("SettingsOverlay/SettingsPanel/Margin/Content/VolumeLabel")
	_volume_slider = get_node("SettingsOverlay/SettingsPanel/Margin/Content/VolumeSlider")
	_reset_cake_styles_button = get_node("SettingsOverlay/SettingsPanel/Margin/Content/ResetCakeStylesButton")
	_settings_back_button = get_node("SettingsOverlay/SettingsPanel/Margin/Content/BackButton")
	_privacy_overlay = get_node("PrivacyOverlay")
	_privacy_panel = get_node("PrivacyOverlay/PrivacyPanel")
	_privacy_margin = get_node("PrivacyOverlay/PrivacyPanel/Margin")
	_privacy_title_label = get_node("PrivacyOverlay/PrivacyPanel/Margin/Content/TitleLabel")
	_privacy_body_scroll = get_node("PrivacyOverlay/PrivacyPanel/Margin/Content/BodyScroll")
	_privacy_body_label = get_node("PrivacyOverlay/PrivacyPanel/Margin/Content/BodyScroll/BodyLabel")
	_privacy_back_button = get_node("PrivacyOverlay/PrivacyPanel/Margin/Content/BackButton")
	_level_select_overlay = get_node("LevelSelectOverlay")
	_level_select_panel = get_node("LevelSelectOverlay/LevelSelectPanel")
	_level_select_margin = get_node("LevelSelectOverlay/LevelSelectPanel/Margin")
	_level_select_title_label = get_node("LevelSelectOverlay/LevelSelectPanel/Margin/Content/TitleLabel")
	_level_grid_scroll = get_node("LevelSelectOverlay/LevelSelectPanel/Margin/Content/LevelGridScroll")
	_level_grid = get_node("LevelSelectOverlay/LevelSelectPanel/Margin/Content/LevelGridScroll/LevelGrid")
	_level_select_back_button = get_node("LevelSelectOverlay/LevelSelectPanel/Margin/Content/BackButton")

	_play_button.pressed.connect(_on_play_pressed)
	_start_game_button.pressed.connect(_on_start_game_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_level_select_button.pressed.connect(_on_level_select_pressed)
	_endless_mode_button.pressed.connect(_on_endless_mode_pressed)
	_privacy_policy_button.pressed.connect(_on_privacy_policy_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_sound_toggle.toggled.connect(_on_sound_toggled)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_reset_cake_styles_button.pressed.connect(_on_reset_cake_styles_pressed)
	_settings_back_button.pressed.connect(_on_settings_back_pressed)
	_privacy_back_button.pressed.connect(_on_privacy_back_pressed)
	_level_select_back_button.pressed.connect(_on_level_select_back_pressed)

	_ui_sound_player.stream = ToneFactory.create_menu_click_sound()

	AppSettings.ensure_loaded()
	GameProgress.ensure_loaded()
	CakeUnlockManager.ensure_loaded()
	_prototype_level_catalog = load(PROTOTYPE_LEVELS_PATH) as PrototypeLevelCatalog
	if _prototype_level_catalog == null:
		_prototype_level_catalog = PrototypeLevelCatalog.new()
	_prototype_level_count = maxi(_prototype_level_catalog.get_level_count(), 1)
	GameProgress.prototype_highest_unlocked_level_index = clampi(GameProgress.prototype_highest_unlocked_level_index, 0, _prototype_level_count - 1)
	GameProgress.prototype_current_level_index = clampi(GameProgress.prototype_current_level_index, 0, GameProgress.prototype_highest_unlocked_level_index)
	_last_viewport_size = get_viewport_rect().size

	_sound_toggle.button_pressed = AppSettings.sound_enabled
	_volume_slider.value = roundi(AppSettings.volume * 100.0)
	build_level_buttons()
	refresh_sound_toggle_text()
	refresh_volume_text()
	refresh_menu_text()
	apply_responsive_layout(_last_viewport_size)

func _process(_delta: float) -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size == _last_viewport_size:
		return
	_last_viewport_size = viewport_size
	apply_responsive_layout(viewport_size)

func refresh_menu_text() -> void:
	var unlocked_level_number := clampi(GameProgress.prototype_highest_unlocked_level_index, 0, _prototype_level_count - 1) + 1
	_subtitle_label.text = "Unlocked: Level %d/%d" % [unlocked_level_number, _prototype_level_count]
	_play_button.text = "Play Level %d" % unlocked_level_number
	_start_game_button.text = "Start From Level 1"
	refresh_endless_button_layout()
	refresh_level_buttons()

func refresh_endless_button_layout() -> void:
	var is_in_menu_buttons := _endless_mode_button.get_parent() == _menu_buttons

	if is_in_menu_buttons:
		_menu_buttons.remove_child(_endless_mode_button)

	_endless_mode_button.visible = false
	_endless_mode_button.disabled = true

func refresh_sound_toggle_text() -> void:
	_sound_toggle.text = "Sound: ON" if AppSettings.sound_enabled else "Sound: OFF"

func refresh_volume_text() -> void:
	_volume_label.text = "Volume: %d%%" % roundi(AppSettings.volume * 100.0)

func play_ui_sound() -> void:
	_ui_sound_player.play()

func _on_play_pressed() -> void:
	play_ui_sound()
	GameProgress.continue_prototype_game(_prototype_level_count)
	get_tree().change_scene_to_file("res://PrototypeGame.tscn")

func _on_start_game_pressed() -> void:
	play_ui_sound()
	GameProgress.start_prototype_game()
	get_tree().change_scene_to_file("res://PrototypeGame.tscn")

func _on_settings_pressed() -> void:
	play_ui_sound()
	_settings_overlay.visible = true
	_privacy_overlay.visible = false
	_level_select_overlay.visible = false

func _on_level_select_pressed() -> void:
	play_ui_sound()
	refresh_level_buttons()
	_level_select_overlay.visible = true
	_settings_overlay.visible = false
	_privacy_overlay.visible = false

func _on_endless_mode_pressed() -> void:
	play_ui_sound()
	get_tree().change_scene_to_file("res://PrototypeGame.tscn")

func _on_privacy_policy_pressed() -> void:
	play_ui_sound()
	_privacy_overlay.visible = true
	_settings_overlay.visible = false
	_level_select_overlay.visible = false

func _on_quit_pressed() -> void:
	play_ui_sound()
	get_tree().quit()

func _on_sound_toggled(button_pressed: bool) -> void:
	AppSettings.set_sound_enabled(button_pressed)
	refresh_sound_toggle_text()

func _on_volume_changed(value: float) -> void:
	AppSettings.set_volume(value / 100.0)
	refresh_volume_text()

func _on_settings_back_pressed() -> void:
	play_ui_sound()
	_settings_overlay.visible = false

func _on_reset_cake_styles_pressed() -> void:
	play_ui_sound()
	CakeUnlockManager.reset_unlocked_variants()

func _on_privacy_back_pressed() -> void:
	play_ui_sound()
	_privacy_overlay.visible = false

func _on_level_select_back_pressed() -> void:
	play_ui_sound()
	_level_select_overlay.visible = false

func build_level_buttons() -> void:
	for child in _level_grid.get_children():
		child.queue_free()
	_level_buttons.clear()

	for i in range(_prototype_level_count):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 64.0)
		button.text = "Level %d" % (i + 1)
		button.pressed.connect(_on_level_button_pressed.bind(i))
		_level_grid.add_child(button)
		_level_buttons.append(button)

func refresh_level_buttons() -> void:
	var highest_unlocked_index := clampi(GameProgress.prototype_highest_unlocked_level_index, 0, _prototype_level_count - 1)
	for i in range(_level_buttons.size()):
		var unlocked := i <= highest_unlocked_index
		_level_buttons[i].visible = true
		_level_buttons[i].disabled = not unlocked
		_level_buttons[i].text = "Level %d" % (i + 1) if unlocked else "Locked %d" % (i + 1)
	apply_responsive_layout(_last_viewport_size)

func _on_level_button_pressed(level_index: int) -> void:
	if level_index > GameProgress.prototype_highest_unlocked_level_index:
		return
	play_ui_sound()
	GameProgress.set_current_prototype_level(level_index, _prototype_level_count)
	get_tree().change_scene_to_file("res://PrototypeGame.tscn")

func apply_responsive_layout(viewport_size: Vector2) -> void:
	apply_privacy_responsive_layout(viewport_size)
	apply_level_select_responsive_layout(viewport_size)

func apply_privacy_responsive_layout(viewport_size: Vector2) -> void:
	var compact := viewport_size.x < 430.0
	var narrow := viewport_size.x < 520.0
	var short_screen := viewport_size.y < 760.0

	_privacy_panel.anchor_left = 0.03 if narrow else 0.08
	_privacy_panel.anchor_right = 0.97 if narrow else 0.92
	_privacy_panel.anchor_top = 0.05 if short_screen else 0.1
	_privacy_panel.anchor_bottom = 0.95 if short_screen else 0.9
	_privacy_panel.offset_left = 0.0
	_privacy_panel.offset_top = 0.0
	_privacy_panel.offset_right = 0.0
	_privacy_panel.offset_bottom = 0.0

	var margin := 14 if compact else 18 if narrow else 24
	_privacy_margin.add_theme_constant_override("margin_left", margin)
	_privacy_margin.add_theme_constant_override("margin_top", margin)
	_privacy_margin.add_theme_constant_override("margin_right", margin)
	_privacy_margin.add_theme_constant_override("margin_bottom", margin)
	_privacy_title_label.add_theme_font_size_override("font_size", 24 if compact else 30)
	_privacy_body_label.add_theme_font_size_override("font_size", 18 if compact else 22)
	_privacy_back_button.custom_minimum_size = Vector2(0.0, 60.0 if compact else 68.0)
	_privacy_back_button.add_theme_font_size_override("font_size", 24 if compact else 28)

	var available_width := (viewport_size.x * (_privacy_panel.anchor_right - _privacy_panel.anchor_left)) - (margin * 2.0)
	_privacy_body_label.custom_minimum_size = Vector2(maxf(available_width - 12.0, 220.0), 0.0)
	_privacy_body_scroll.custom_minimum_size = Vector2(0.0, 260.0 if short_screen else 320.0)

func apply_level_select_responsive_layout(viewport_size: Vector2) -> void:
	var compact := viewport_size.x < 430.0
	var narrow := viewport_size.x < 520.0
	var very_short := viewport_size.y < 760.0
	var ultra_short := viewport_size.y < 680.0

	_level_select_panel.anchor_left = 0.03 if narrow else 0.06
	_level_select_panel.anchor_right = 0.97 if narrow else 0.94
	_level_select_panel.anchor_top = 0.05 if ultra_short else 0.08 if very_short else 0.12
	_level_select_panel.anchor_bottom = 0.97 if ultra_short else 0.94 if very_short else 0.88
	_level_select_panel.offset_left = 0.0
	_level_select_panel.offset_top = 0.0
	_level_select_panel.offset_right = 0.0
	_level_select_panel.offset_bottom = 0.0

	var margin := 12 if ultra_short else 14 if compact else 18 if narrow else 22
	_level_select_margin.add_theme_constant_override("margin_left", margin)
	_level_select_margin.add_theme_constant_override("margin_top", margin)
	_level_select_margin.add_theme_constant_override("margin_right", margin)
	_level_select_margin.add_theme_constant_override("margin_bottom", margin)
	_level_select_title_label.add_theme_font_size_override("font_size", 22 if ultra_short else 24 if compact else 30)
	_level_grid.columns = 2 if compact or very_short else 3
	_level_grid_scroll.custom_minimum_size = Vector2(0.0, 220.0 if ultra_short else 260.0 if very_short else 340.0)
	_level_grid.add_theme_constant_override("h_separation", 8 if ultra_short else 10 if compact else 14)
	_level_grid.add_theme_constant_override("v_separation", 8 if ultra_short else 10 if compact else 14)
	_level_select_back_button.custom_minimum_size = Vector2(0.0, 54.0 if ultra_short else 60.0 if compact else 68.0)
	_level_select_back_button.add_theme_font_size_override("font_size", 22 if ultra_short else 24 if compact else 28)

	for button in _level_buttons:
		button.custom_minimum_size = Vector2(0.0, 46.0 if ultra_short else 54.0 if compact else 64.0)
		button.add_theme_font_size_override("font_size", 16 if ultra_short else 18 if compact else 22)
