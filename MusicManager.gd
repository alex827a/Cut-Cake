extends Node

const MUSIC_PATH := "res://music/cyberwave_orchestra_upbeat_background_loop_casual_video_game_music.mp3"

var _player: AudioStreamPlayer

func _ready() -> void:
	AppSettings.ensure_loaded()

	_player = AudioStreamPlayer.new()
	_player.name = "BackgroundMusicPlayer"
	_player.volume_db = -22.0
	add_child(_player)

	var stream := load(MUSIC_PATH) as AudioStream
	if stream == null:
		push_warning("Background music not found at %s" % MUSIC_PATH)
		return

	_player.stream = stream
	_player.finished.connect(_on_track_finished)
	_player.play()

func _on_track_finished() -> void:
	if _player.stream != null:
		_player.play()
