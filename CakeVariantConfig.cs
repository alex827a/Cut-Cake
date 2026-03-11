using Godot;
using System.Collections.Generic;

public sealed class CakeVariantConfig
{
    private readonly string[] _blockTexturePaths;
    private readonly string? _previewTexturePath;
    private List<Texture2D>? _cachedBlockTextures;
    private Texture2D? _cachedPreviewTexture;

    public CakeVariantConfig(int variantId, string displayName, int unlockLevel, string[] blockTexturePaths, string? previewTexturePath = null)
    {
        VariantId = variantId;
        DisplayName = displayName;
        UnlockLevel = unlockLevel;
        _blockTexturePaths = blockTexturePaths;
        _previewTexturePath = previewTexturePath;
    }

    public int VariantId { get; }
    public string DisplayName { get; }
    public int UnlockLevel { get; }

    public IReadOnlyList<Texture2D> GetBlockTextures(IReadOnlyList<Texture2D> fallbackTextures)
    {
        if (_cachedBlockTextures == null)
        {
            _cachedBlockTextures = new List<Texture2D>();
            foreach (var path in _blockTexturePaths)
            {
                var texture = ResourceLoader.Load<Texture2D>(path);
                if (texture != null)
                {
                    _cachedBlockTextures.Add(texture);
                }
            }
        }

        return _cachedBlockTextures.Count > 0 ? _cachedBlockTextures : fallbackTextures;
    }

    public Texture2D? GetPreviewTexture(IReadOnlyList<Texture2D> fallbackTextures)
    {
        if (_cachedPreviewTexture == null && !string.IsNullOrWhiteSpace(_previewTexturePath))
        {
            _cachedPreviewTexture = ResourceLoader.Load<Texture2D>(_previewTexturePath);
        }

        if (_cachedPreviewTexture != null)
        {
            return _cachedPreviewTexture;
        }

        var textures = GetBlockTextures(fallbackTextures);
        return textures.Count > 0 ? textures[0] : null;
    }
}
