using Godot;

public static class GameProgress
{
    private const string SavePath = "user://progress.cfg";
    private const string SaveSection = "progress";
    private const string UnlockedKey = "highest_unlocked_level";
    private const string EndlessUnlockedKey = "endless_unlocked";
    private const string BestEndlessScoreKey = "best_endless_score";

    private static readonly LevelConfig[] _levels =
    {
        new(8, 300.0f, 190.0f, 140.0f, 24.0f),
        new(8, 288.0f, 205.0f, 150.0f, 24.0f),
        new(9, 276.0f, 220.0f, 160.0f, 23.0f),
        new(9, 264.0f, 235.0f, 170.0f, 22.0f),
        new(10, 252.0f, 250.0f, 175.0f, 22.0f),
        new(10, 240.0f, 265.0f, 185.0f, 21.0f),
        new(11, 228.0f, 280.0f, 195.0f, 20.0f),
        new(11, 216.0f, 300.0f, 205.0f, 19.0f),
        new(12, 204.0f, 320.0f, 215.0f, 18.0f),
        new(12, 192.0f, 340.0f, 225.0f, 18.0f),
        new(13, 184.0f, 355.0f, 230.0f, 17.5f),
        new(13, 176.0f, 370.0f, 235.0f, 17.0f),
        new(14, 168.0f, 385.0f, 240.0f, 16.5f),
        new(14, 160.0f, 400.0f, 245.0f, 16.0f),
        new(15, 154.0f, 420.0f, 250.0f, 15.5f),
        new(15, 148.0f, 440.0f, 255.0f, 15.0f),
        new(16, 142.0f, 460.0f, 260.0f, 14.5f),
        new(17, 136.0f, 480.0f, 270.0f, 14.0f),
        new(18, 130.0f, 500.0f, 280.0f, 13.5f),
        new(20, 124.0f, 525.0f, 290.0f, 13.0f)
    };

    private static bool _loaded;

    public static int CurrentLevelIndex { get; private set; }
    public static int HighestUnlockedLevelIndex { get; private set; }
    public static bool EndlessModeUnlocked { get; private set; }
    public static int BestEndlessScore { get; private set; }
    public static GameMode CurrentGameMode { get; private set; } = GameMode.Level;
    public static int TotalLevels => _levels.Length;

    public static void EnsureLoaded()
    {
        if (_loaded)
        {
            return;
        }

        HighestUnlockedLevelIndex = 0;
        CurrentLevelIndex = 0;
        EndlessModeUnlocked = false;
        BestEndlessScore = 0;
        CurrentGameMode = GameMode.Level;

        var config = new ConfigFile();
        if (config.Load(SavePath) == Error.Ok)
        {
            HighestUnlockedLevelIndex = Mathf.Clamp((int)config.GetValue(SaveSection, UnlockedKey, 0), 0, _levels.Length - 1);
            EndlessModeUnlocked = (bool)config.GetValue(SaveSection, EndlessUnlockedKey, false);
            BestEndlessScore = Mathf.Max(0, (int)config.GetValue(SaveSection, BestEndlessScoreKey, 0));
        }

        _loaded = true;
    }

    public static LevelConfig GetCurrentLevel()
    {
        EnsureLoaded();
        return _levels[CurrentLevelIndex];
    }

    public static void StartGame()
    {
        EnsureLoaded();
        CurrentGameMode = GameMode.Level;
        CurrentLevelIndex = 0;
    }

    public static void ContinueGame()
    {
        EnsureLoaded();
        CurrentGameMode = GameMode.Level;
        CurrentLevelIndex = HighestUnlockedLevelIndex;
    }

    public static void SetCurrentLevel(int levelIndex)
    {
        EnsureLoaded();
        CurrentGameMode = GameMode.Level;
        CurrentLevelIndex = Mathf.Clamp(levelIndex, 0, HighestUnlockedLevelIndex);
    }

    public static void StartEndlessMode()
    {
        EnsureLoaded();
        CurrentGameMode = GameMode.Endless;
        CurrentLevelIndex = _levels.Length - 1;
    }

    public static bool HasNextLevel(int fromLevelIndex)
    {
        return fromLevelIndex < _levels.Length - 1;
    }

    public static bool AdvanceToNextLevel()
    {
        EnsureLoaded();
        if (!HasNextLevel(CurrentLevelIndex))
        {
            return false;
        }

        CurrentLevelIndex++;
        return true;
    }

    public static void CompleteCurrentLevel()
    {
        EnsureLoaded();

        var nextUnlockedLevel = Mathf.Min(CurrentLevelIndex + 1, _levels.Length - 1);
        var progressionChanged = false;

        if (nextUnlockedLevel > HighestUnlockedLevelIndex)
        {
            HighestUnlockedLevelIndex = nextUnlockedLevel;
            progressionChanged = true;
        }

        if (!EndlessModeUnlocked && CurrentLevelIndex >= _levels.Length - 1)
        {
            EndlessModeUnlocked = true;
            progressionChanged = true;
        }

        if (progressionChanged)
        {
            Save();
        }
    }

    public static bool TrySetBestEndlessScore(int score)
    {
        EnsureLoaded();

        if (score <= BestEndlessScore)
        {
            return false;
        }

        BestEndlessScore = score;
        Save();
        return true;
    }

    private static void Save()
    {
        var config = new ConfigFile();
        config.SetValue(SaveSection, UnlockedKey, HighestUnlockedLevelIndex);
        config.SetValue(SaveSection, EndlessUnlockedKey, EndlessModeUnlocked);
        config.SetValue(SaveSection, BestEndlessScoreKey, BestEndlessScore);

        var result = config.Save(SavePath);
        if (result != Error.Ok)
        {
            GD.PushWarning($"Failed to save progression to {SavePath}: {result}");
        }
    }
}
