using Godot;

public static class AppSettings
{
    private const string SavePath = "user://settings.cfg";
    private const string SaveSection = "settings";
    private const string SoundEnabledKey = "sound_enabled";
    private const string VolumeKey = "volume";

    private static bool _loaded;

    public static bool SoundEnabled { get; private set; } = true;
    public static float Volume { get; private set; } = 0.75f;

    public static void EnsureLoaded()
    {
        if (_loaded)
        {
            return;
        }

        var config = new ConfigFile();
        if (config.Load(SavePath) == Error.Ok)
        {
            SoundEnabled = (bool)config.GetValue(SaveSection, SoundEnabledKey, true);
            Volume = Mathf.Clamp((float)config.GetValue(SaveSection, VolumeKey, 0.75f), 0.0f, 1.0f);
        }

        ApplyAudioState();
        _loaded = true;
    }

    public static void SetSoundEnabled(bool enabled)
    {
        EnsureLoaded();
        SoundEnabled = enabled;
        ApplyAudioState();
        Save();
    }

    public static void SetVolume(float volume)
    {
        EnsureLoaded();
        Volume = Mathf.Clamp(volume, 0.0f, 1.0f);
        ApplyAudioState();
        Save();
    }

    private static void ApplyAudioState()
    {
        var busIndex = AudioServer.GetBusIndex("Master");
        if (busIndex >= 0)
        {
            AudioServer.SetBusMute(busIndex, !SoundEnabled);
            AudioServer.SetBusVolumeDb(busIndex, ConvertLinearVolumeToDb(Volume));
        }
    }

    private static float ConvertLinearVolumeToDb(float volume)
    {
        if (volume <= 0.001f)
        {
            return -80.0f;
        }

        return Mathf.LinearToDb(volume);
    }

    private static void Save()
    {
        var config = new ConfigFile();
        config.SetValue(SaveSection, SoundEnabledKey, SoundEnabled);
        config.SetValue(SaveSection, VolumeKey, Volume);

        var result = config.Save(SavePath);
        if (result != Error.Ok)
        {
            GD.PushWarning($"Failed to save settings to {SavePath}: {result}");
        }
    }
}
