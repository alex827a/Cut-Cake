class_name AppSettings
extends RefCounted

const SAVE_PATH := "user://settings.cfg"
const SAVE_SECTION := "settings"
const SOUND_ENABLED_KEY := "sound_enabled"
const VOLUME_KEY := "volume"

static var _loaded := false
static var sound_enabled := true
static var volume := 0.75

static func ensure_loaded() -> void:
	if _loaded:
		return

	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		sound_enabled = bool(config.get_value(SAVE_SECTION, SOUND_ENABLED_KEY, true))
		volume = clampf(float(config.get_value(SAVE_SECTION, VOLUME_KEY, 0.75)), 0.0, 1.0)

	apply_audio_state()
	_loaded = true

static func set_sound_enabled(enabled: bool) -> void:
	ensure_loaded()
	sound_enabled = enabled
	apply_audio_state()
	save()

static func set_volume(value: float) -> void:
	ensure_loaded()
	volume = clampf(value, 0.0, 1.0)
	apply_audio_state()
	save()

static func apply_audio_state() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, not sound_enabled)
		AudioServer.set_bus_volume_db(bus_index, convert_linear_volume_to_db(volume))

static func convert_linear_volume_to_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(value)

static func save() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, SOUND_ENABLED_KEY, sound_enabled)
	config.set_value(SAVE_SECTION, VOLUME_KEY, volume)

	var result := config.save(SAVE_PATH)
	if result != OK:
		push_warning("Failed to save settings to %s: %s" % [SAVE_PATH, result])
