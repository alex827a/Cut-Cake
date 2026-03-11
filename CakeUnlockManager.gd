class_name CakeUnlockManager
extends RefCounted

const SAVE_PATH := "user://cake_unlocks.cfg"
const SAVE_SECTION := "cake_unlocks"
const VARIANT_KEY := "highest_unlocked_variant"
const PROTOTYPE_CAKE_TEXTURE_PATHS: PackedStringArray = [
	"res://cake_1.png",
	"res://cake_2.png",
	"res://cake_3.png",
	"res://cake_4.png"
]

static var _variants: Array[CakeVariantConfig] = [
	CakeVariantConfig.new(0, "Strawberry Kiss", 0, PackedStringArray(["res://cake_1.png"]), "res://cake_1.png"),
	CakeVariantConfig.new(1, "Berry Bloom", 4, PackedStringArray(["res://cake_2.png"]), "res://cake_2.png"),
	CakeVariantConfig.new(2, "Chocolate Charm", 8, PackedStringArray(["res://cake_3.png"]), "res://cake_3.png"),
	CakeVariantConfig.new(3, "Cherry Crown", 12, PackedStringArray(["res://cake_4.png"]), "res://cake_4.png")
]

static var _loaded := false
static var highest_unlocked_variant_index := 0
static var _cached_prototype_textures: Array[Texture2D] = []
static var _prototype_textures_loaded := false

static func ensure_loaded() -> void:
	if _loaded:
		return

	highest_unlocked_variant_index = 0
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		highest_unlocked_variant_index = clampi(int(config.get_value(SAVE_SECTION, VARIANT_KEY, 0)), 0, _variants.size() - 1)

	_loaded = true

static func get_unlocked_variants() -> Array[CakeVariantConfig]:
	ensure_loaded()
	var unlocked: Array[CakeVariantConfig] = []
	for i in range(mini(highest_unlocked_variant_index + 1, _variants.size())):
		unlocked.append(_variants[i])
	return unlocked

static func try_unlock_for_completed_level(completed_level: int) -> CakeVariantConfig:
	ensure_loaded()
	for variant in _variants:
		if variant.unlock_level != completed_level:
			continue
		if variant.variant_id <= highest_unlocked_variant_index:
			return null
		highest_unlocked_variant_index = variant.variant_id
		save()
		return variant
	return null

static func reset_unlocked_variants() -> void:
	ensure_loaded()
	highest_unlocked_variant_index = 0
	save()

static func get_unlocked_prototype_cake_textures() -> Array[Texture2D]:
	ensure_loaded()
	if not _prototype_textures_loaded:
		_prototype_textures_loaded = true
		for texture_path in PROTOTYPE_CAKE_TEXTURE_PATHS:
			var texture := load(texture_path) as Texture2D
			if texture != null:
				_cached_prototype_textures.append(texture)

	var max_index: int = mini(highest_unlocked_variant_index, _cached_prototype_textures.size() - 1)
	var unlocked_textures: Array[Texture2D] = []
	for i in range(max_index + 1):
		unlocked_textures.append(_cached_prototype_textures[i])
	return unlocked_textures

static func get_prototype_cake_texture_for_spawn(spawn_index: int) -> Texture2D:
	var unlocked_textures: Array[Texture2D] = get_unlocked_prototype_cake_textures()
	if unlocked_textures.is_empty():
		return null
	return unlocked_textures[posmod(spawn_index, unlocked_textures.size())]

static func save() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, VARIANT_KEY, highest_unlocked_variant_index)
	var result := config.save(SAVE_PATH)
	if result != OK:
		push_warning("Failed to save cake unlocks to %s: %s" % [SAVE_PATH, result])
