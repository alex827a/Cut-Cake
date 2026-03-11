using Godot;

public partial class MusicManager : Node
{
	private const string MusicPath = "res://music/cyberwave_orchestra_upbeat_background_loop_casual_video_game_music.mp3";

	private AudioStreamPlayer _player = null!;

	public override void _Ready()
	{
		AppSettings.EnsureLoaded();

		_player = new AudioStreamPlayer
		{
			Name = "BackgroundMusicPlayer",
			VolumeDb = -16.0f
		};
		AddChild(_player);

		var stream = ResourceLoader.Load<AudioStream>(MusicPath);
		if (stream == null)
		{
			GD.PushWarning($"Background music not found at {MusicPath}");
			return;
		}

		_player.Stream = stream;
		_player.Finished += OnTrackFinished;
		_player.Play();
	}

	private void OnTrackFinished()
	{
		if (_player.Stream != null)
		{
			_player.Play();
		}
	}
}
