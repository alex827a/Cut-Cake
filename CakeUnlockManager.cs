using Godot;
using System.Collections.Generic;

public static class CakeUnlockManager
{
    private const string SavePath = "user://cake_unlocks.cfg";
    private const string SaveSection = "cake_unlocks";
    private const string VariantKey = "highest_unlocked_variant";

    private static readonly CakeVariantConfig[] _variants =
    {
        new(0, "Strawberry Start", 0, new[] { "res://frisrblock.png" }, "res://frisrblock.png"),
        new(1, "Berry Cream", 5, new[] { "res://secondblock.png" }, "res://secondblock.png"),
        new(2, "Vanilla Party", 10, new[] { "res://thirdblock.png" }, "res://thirdblock.png"),
        new(3, "Choco Celebration", 18, new[] { "res://fourblock.png" }, "res://fourblock.png")
    };

    private static bool _loaded;

    public static int HighestUnlockedVariantIndex { get; private set; }
    public static int TotalVariants => _variants.Length;

    public static void EnsureLoaded()
    {
        if (_loaded)
        {
            return;
        }

        HighestUnlockedVariantIndex = 0;

        var config = new ConfigFile();
        if (config.Load(SavePath) == Error.Ok)
        {
            HighestUnlockedVariantIndex = Mathf.Clamp((int)config.GetValue(SaveSection, VariantKey, 0), 0, _variants.Length - 1);
        }

        _loaded = true;
    }

    public static IReadOnlyList<CakeVariantConfig> GetUnlockedVariants()
    {
        EnsureLoaded();

        var unlocked = new List<CakeVariantConfig>();
        for (var i = 0; i <= HighestUnlockedVariantIndex && i < _variants.Length; i++)
        {
            unlocked.Add(_variants[i]);
        }

        return unlocked;
    }

    public static CakeVariantConfig GetVariantForLevel(int levelIndex)
    {
        var unlocked = GetUnlockedVariants();
        return unlocked[levelIndex % unlocked.Count];
    }

    public static bool TryUnlockForCompletedLevel(int completedLevel, out CakeVariantConfig? unlockedVariant)
    {
        EnsureLoaded();
        unlockedVariant = null;

        foreach (var variant in _variants)
        {
            if (variant.UnlockLevel != completedLevel)
            {
                continue;
            }

            if (variant.VariantId <= HighestUnlockedVariantIndex)
            {
                return false;
            }

            HighestUnlockedVariantIndex = variant.VariantId;
            Save();
            unlockedVariant = variant;
            return true;
        }

        return false;
    }

    public static void ResetUnlockedVariants()
    {
        EnsureLoaded();
        HighestUnlockedVariantIndex = 0;
        Save();
    }

    private static void Save()
    {
        var config = new ConfigFile();
        config.SetValue(SaveSection, VariantKey, HighestUnlockedVariantIndex);

        var result = config.Save(SavePath);
        if (result != Error.Ok)
        {
            GD.PushWarning($"Failed to save cake unlocks to {SavePath}: {result}");
        }
    }
}
