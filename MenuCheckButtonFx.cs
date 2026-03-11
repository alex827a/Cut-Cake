using Godot;

public partial class MenuCheckButtonFx : CheckButton
{
    [Export]
    public float HoverScale { get; set; } = 1.05f;

    [Export]
    public float PressedScale { get; set; } = 0.95f;

    [Export]
    public float AnimationDuration { get; set; } = 0.08f;

    private Tween? _scaleTween;
    private bool _isHovered;
    private bool _isPressed;

    public override void _Ready()
    {
        MouseEntered += OnMouseEntered;
        MouseExited += OnMouseExited;
        ButtonDown += OnButtonDown;
        ButtonUp += OnButtonUp;
        Resized += UpdatePivotOffset;

        UpdatePivotOffset();
    }

    private void OnMouseEntered()
    {
        _isHovered = true;
        AnimateToCurrentState();
    }

    private void OnMouseExited()
    {
        _isHovered = false;
        _isPressed = false;
        AnimateToCurrentState();
    }

    private void OnButtonDown()
    {
        _isPressed = true;
        AnimateToCurrentState();
    }

    private void OnButtonUp()
    {
        _isPressed = false;
        AnimateToCurrentState();
    }

    private void UpdatePivotOffset()
    {
        PivotOffset = Size * 0.5f;
    }

    private void AnimateToCurrentState()
    {
        var targetScale = Vector2.One;
        if (_isPressed)
        {
            targetScale = new Vector2(PressedScale, PressedScale);
        }
        else if (_isHovered)
        {
            targetScale = new Vector2(HoverScale, HoverScale);
        }

        _scaleTween?.Kill();
        _scaleTween = CreateTween();
        _scaleTween.TweenProperty(this, "scale", targetScale, AnimationDuration)
            .SetTrans(Tween.TransitionType.Quad)
            .SetEase(Tween.EaseType.Out);
    }
}
