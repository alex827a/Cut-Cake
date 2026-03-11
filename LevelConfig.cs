public sealed class LevelConfig
{
    public LevelConfig(int requiredBlocksToWin, float initialBlockWidth, float blockMoveSpeed, float horizontalMoveRange, float minValidOverlap)
    {
        RequiredBlocksToWin = requiredBlocksToWin;
        InitialBlockWidth = initialBlockWidth;
        BlockMoveSpeed = blockMoveSpeed;
        HorizontalMoveRange = horizontalMoveRange;
        MinValidOverlap = minValidOverlap;
    }

    public int RequiredBlocksToWin { get; }
    public float InitialBlockWidth { get; }
    public float BlockMoveSpeed { get; }
    public float HorizontalMoveRange { get; }
    public float MinValidOverlap { get; }
}
