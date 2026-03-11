class_name CakeVariantConfig
extends RefCounted

var variant_id: int
var display_name: String
var unlock_level: int
var _block_texture_paths: PackedStringArray
var _preview_texture_path: String
var _cached_block_textures: Array[Texture2D] = []
var _has_loaded_block_textures := false
var _cached_preview_texture: Texture2D
var _has_loaded_preview_texture := false

func _init(new_variant_id: int, new_display_name: String, new_unlock_level: int, block_texture_paths: PackedStringArray, preview_texture_path: String = "") -> void:
	variant_id = new_variant_id
	display_name = new_display_name
	unlock_level = new_unlock_level
	_block_texture_paths = block_texture_paths
	_preview_texture_path = preview_texture_path

func get_block_textures(fallback_textures: Array[Texture2D]) -> Array[Texture2D]:
	if not _has_loaded_block_textures:
		_has_loaded_block_textures = true
		for path in _block_texture_paths:
			var texture := load(path) as Texture2D
			if texture != null:
				_cached_block_textures.append(texture)

	if not _cached_block_textures.is_empty():
		return _cached_block_textures
	return fallback_textures

func get_preview_texture(fallback_textures: Array[Texture2D]) -> Texture2D:
	if not _has_loaded_preview_texture:
		_has_loaded_preview_texture = true
		if not _preview_texture_path.is_empty():
			_cached_preview_texture = load(_preview_texture_path) as Texture2D

	if _cached_preview_texture != null:
		return _cached_preview_texture

	var textures := get_block_textures(fallback_textures)
	if textures.is_empty():
		return null
	return textures[0]
