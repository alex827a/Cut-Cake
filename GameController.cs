using Godot;
using System;
using System.Collections.Generic;

public partial class GameController : Node2D
{
	[Export]
	public PackedScene? BlockScene { get; set; }

	[Export]
	public Texture2D? BlockTexture1 { get; set; }

	[Export]
	public Texture2D? BlockTexture2 { get; set; }

	[Export]
	public Texture2D? BlockTexture3 { get; set; }

	[Export]
	public Texture2D? BlockTexture4 { get; set; }

	[Export]
	public float BlockHeightStep { get; set; } = 48.0f;

	[Export]
	public float PerfectPlacementThreshold { get; set; } = 4.0f;

	[Export]
	public float NearPerfectPlacementThreshold { get; set; } = 12.0f;

	[Export]
	public float CameraLiftPerBlock { get; set; } = 16.0f;

	[Export]
	public float EndlessCameraLiftPerBlock { get; set; } = 42.0f;

	[Export]
	public int EndlessCameraStartBlock { get; set; } = 4;

	[Export]
	public float CameraUiSafePadding { get; set; } = 28.0f;

	[Export]
	public float CutFallDistance { get; set; } = 300.0f;

	[Export]
	public float CutHorizontalDrift { get; set; } = 72.0f;

	[Export]
	public float CutFallDuration { get; set; } = 0.9f;

	private readonly Color[] _blockColors =
	{
		new(0.20f, 0.56f, 0.95f, 1.0f),
		new(0.15f, 0.78f, 0.67f, 1.0f),
		new(0.96f, 0.75f, 0.22f, 1.0f),
		new(0.95f, 0.47f, 0.31f, 1.0f),
		new(0.70f, 0.45f, 0.95f, 1.0f)
	};

	private Camera2D _camera = null!;
	private ColorRect _backdropTop = null!;
	private ColorRect _backdropBottom = null!;
	private Sprite2D _cakePlate = null!;
	private Sprite2D _cakePlateShadow = null!;
	private Sprite2D _towerShadow = null!;
	private MovingBlock _basePlatform = null!;
	private Node2D _placedBlocksRoot = null!;
	private Marker2D _currentBlockSpawn = null!;
	private PanelContainer _topPanel = null!;
	private MarginContainer _topPanelMargin = null!;
	private HBoxContainer _topRow = null!;
	private PanelContainer _statusPanel = null!;
	private HBoxContainer _actionButtons = null!;
	private Label _levelLabel = null!;
	private Label _progressLabel = null!;
	private Label _statusLabel = null!;
	private Button _restartButton = null!;
	private Button _nextLevelButton = null!;
	private Button _backToMenuButton = null!;
	private Label _tapHintLabel = null!;
	private Label _perfectLabel = null!;
	private Label _levelCompleteLabel = null!;
	private Control _unlockPopup = null!;
	private Label _unlockPopupLabel = null!;
	private TextureRect _unlockPopupPreview = null!;
	private AudioStreamPlayer _placeSoundPlayer = null!;
	private AudioStreamPlayer _resultSoundPlayer = null!;
	private CpuParticles2D _sprinkleParticles = null!;
	private readonly List<Polygon2D> _clouds = new();
	private readonly List<Vector2> _cloudBaseOffsets = new();
	private readonly List<float> _cloudDriftSpeeds = new();

	private Vector2 _basePlatformStartPosition;
	private Vector2 _lastViewportSize;
	private float _spawnBaseY;
	private Vector2 _cameraStartPosition;
	private Vector2 _cameraBasePosition;
	private float _highestCloudAnchorY;
	private bool _gameActive;
	private int _placedBlockCount;
	private int _activeLevelIndex;
	private LevelConfig _activeLevel = null!;
	private GameMode _gameMode;
	private IReadOnlyList<CakeVariantConfig> _unlockedCakeVariants = Array.Empty<CakeVariantConfig>();
	private MovingBlock _referenceBlock = null!;
	private MovingBlock? _currentBlock;
	private float _cameraShakeTimeLeft;
	private float _cameraShakeStrength;
	private readonly RandomNumberGenerator _random = new();
	private readonly List<Texture2D> _defaultBlockTextures = new();

	public override void _Ready()
	{
		_camera = GetNode<Camera2D>("Camera2D");
		_backdropTop = GetNode<ColorRect>("BackdropTop");
		_backdropBottom = GetNode<ColorRect>("BackdropBottom");
		_cakePlate = GetNode<Sprite2D>("CakePlate");
		_cakePlateShadow = GetNode<Sprite2D>("CakePlateShadow");
		_towerShadow = GetNode<Sprite2D>("TowerShadow");
		_basePlatform = GetNode<MovingBlock>("BasePlatform");
		_placedBlocksRoot = GetNode<Node2D>("PlacedBlocksRoot");
		_currentBlockSpawn = GetNode<Marker2D>("CurrentBlockSpawn");
		_topPanel = GetNode<PanelContainer>("UI/TopPanel");
		_topPanelMargin = GetNode<MarginContainer>("UI/TopPanel/Margin");
		_topRow = GetNode<HBoxContainer>("UI/TopPanel/Margin/TopRow");
		_statusPanel = GetNode<PanelContainer>("UI/StatusPanel");
		_actionButtons = GetNode<HBoxContainer>("UI/ActionButtons");
		_levelLabel = GetNode<Label>("UI/TopPanel/Margin/TopRow/InfoBox/LevelLabel");
		_progressLabel = GetNode<Label>("UI/TopPanel/Margin/TopRow/InfoBox/ProgressLabel");
		_statusLabel = GetNode<Label>("UI/StatusPanel/StatusLabel");
		_restartButton = GetNode<Button>("UI/ActionButtons/RestartButton");
		_nextLevelButton = GetNode<Button>("UI/ActionButtons/NextLevelButton");
		_backToMenuButton = GetNode<Button>("UI/TopPanel/Margin/TopRow/BackToMenuButton");
		_tapHintLabel = GetNode<Label>("UI/TapHintLabel");
		_perfectLabel = GetNode<Label>("UI/PerfectLabel");
		_levelCompleteLabel = GetNode<Label>("UI/LevelCompleteLabel");
		_unlockPopup = GetNode<Control>("UI/UnlockPopup");
		_unlockPopupLabel = GetNode<Label>("UI/UnlockPopup/Panel/Margin/Content/UnlockLabel");
		_unlockPopupPreview = GetNode<TextureRect>("UI/UnlockPopup/Panel/Margin/Content/UnlockPreview");
		_placeSoundPlayer = GetNode<AudioStreamPlayer>("PlaceSoundPlayer");
		_resultSoundPlayer = GetNode<AudioStreamPlayer>("ResultSoundPlayer");
		_sprinkleParticles = GetNode<CpuParticles2D>("SprinkleParticles");

		_basePlatformStartPosition = _basePlatform.GlobalPosition;
		_spawnBaseY = _currentBlockSpawn.GlobalPosition.Y;
		_cameraStartPosition = _camera.Position;
		_cameraBasePosition = _cameraStartPosition;
		_lastViewportSize = GetViewportRect().Size;

		_restartButton.Pressed += OnRestartPressed;
		_nextLevelButton.Pressed += OnNextLevelPressed;
		_backToMenuButton.Pressed += OnBackToMenuPressed;

		AppSettings.EnsureLoaded();
		GameProgress.EnsureLoaded();
		CakeUnlockManager.EnsureLoaded();
		BuildDefaultTextureList();

		_placeSoundPlayer.Stream = ToneFactory.CreateCakeStackSound();
		_resultSoundPlayer.Stream = ToneFactory.CreateGentleWinSound();
		SetupDecorativeSprites();
		SetupBackgroundDecor();
		ConfigureSprinkleParticles();
		ApplyResponsiveUi(_lastViewportSize);
		StartLevel();
	}

	public override void _Process(double delta)
	{
		var viewportSize = GetViewportRect().Size;
		if (viewportSize != _lastViewportSize)
		{
			_lastViewportSize = viewportSize;
			ApplyResponsiveUi(viewportSize);
		}

		if (_cameraShakeTimeLeft > 0.0f)
		{
			_cameraShakeTimeLeft = Mathf.Max(0.0f, _cameraShakeTimeLeft - (float)delta);
			var decay = _cameraShakeTimeLeft / 0.12f;
			var offset = new Vector2(
				_random.RandfRange(-_cameraShakeStrength, _cameraShakeStrength),
				_random.RandfRange(-_cameraShakeStrength, _cameraShakeStrength)) * decay;
			_camera.Position = _cameraBasePosition + offset;

			if (_cameraShakeTimeLeft <= 0.0f)
			{
				_camera.Position = _cameraBasePosition;
			}
		}

		UpdateBackgroundVisuals();
	}

	public override void _Input(InputEvent @event)
	{
		if (!_gameActive || _currentBlock == null)
		{
			return;
		}

		var placePressed = false;
		var pointerPosition = Vector2.Zero;

		if (@event is InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left } mouseButton)
		{
			if (ShouldIgnoreMousePlacementInput())
			{
				return;
			}

			placePressed = true;
			pointerPosition = mouseButton.Position;
		}
		else if (@event is InputEventScreenTouch { Pressed: true } screenTouch)
		{
			placePressed = true;
			pointerPosition = screenTouch.Position;
		}

		if (!placePressed)
		{
			return;
		}

		if (IsPointerOverButton(pointerPosition))
		{
			return;
		}

		GetViewport().SetInputAsHandled();
		PlaceCurrentBlock();
	}

	private static bool IsTouchEmulatedFromMouseEnabled()
	{
		return ProjectSettings.HasSetting("input_devices/pointing/emulate_touch_from_mouse")
			&& ProjectSettings.GetSetting("input_devices/pointing/emulate_touch_from_mouse").AsBool();
	}

	private static bool ShouldIgnoreMousePlacementInput()
	{
		return OS.HasFeature("mobile") || IsTouchEmulatedFromMouseEnabled();
	}

	private void StartLevel()
	{
		foreach (var child in _placedBlocksRoot.GetChildren())
		{
			child.QueueFree();
		}

		_activeLevelIndex = GameProgress.CurrentLevelIndex;
		_activeLevel = GameProgress.GetCurrentLevel();
		_gameMode = GameProgress.CurrentGameMode;
		_unlockedCakeVariants = CakeUnlockManager.GetUnlockedVariants();
		_currentBlock = null;
		_placedBlockCount = 0;
		_gameActive = true;

		_basePlatform.StopMovement();
		_basePlatform.Scale = Vector2.One;
		_basePlatform.Modulate = Colors.White;
		_basePlatform.SnapTo(_basePlatformStartPosition.X, _basePlatformStartPosition.Y);
		_basePlatform.SetHeight(BlockHeightStep);
		_basePlatform.SetWidth(_activeLevel.InitialBlockWidth);
		_basePlatform.SetBlockTexture(GetBlockTexture(0));
		_basePlatform.SetBlockColor(GetBlockColor(0));

		_referenceBlock = _basePlatform;

		_camera.Position = _cameraStartPosition;
		_cameraBasePosition = _cameraStartPosition;
		_cameraShakeTimeLeft = 0.0f;
		_perfectLabel.Visible = false;
		_perfectLabel.Scale = Vector2.Zero;
		_perfectLabel.Modulate = Colors.White;
		_levelCompleteLabel.Visible = false;
		_levelCompleteLabel.Scale = Vector2.Zero;
		_levelCompleteLabel.Modulate = new Color(1.0f, 0.819608f, 0.4f, 0.0f);
		_unlockPopup.Visible = false;
		_unlockPopup.Scale = Vector2.One * 0.8f;
		_unlockPopup.Modulate = new Color(1.0f, 1.0f, 1.0f, 0.0f);
		_levelLabel.Text = _gameMode == GameMode.Endless ? "Endless Mode" : $"Level {_activeLevelIndex + 1}";
		_statusLabel.Modulate = Colors.White;
		_statusLabel.Text = "Line up the block";
		_tapHintLabel.Visible = true;
		_tapHintLabel.Text = "Tap or click to stack";
		_restartButton.Visible = false;
		_restartButton.Disabled = true;
		_nextLevelButton.Visible = false;
		_nextLevelButton.Disabled = true;
		_backToMenuButton.Disabled = false;

		UpdateProgressLabel();
		UpdateTowerDecor();
		ResetBackgroundVisuals();
		SpawnNextBlock();
	}

	private void SpawnNextBlock()
	{
		if (BlockScene == null)
		{
			GD.PushError("BlockScene is not assigned on GameController.");
			return;
		}

		var nextBlock = BlockScene.Instantiate<MovingBlock>();
		_placedBlocksRoot.AddChild(nextBlock);

		var spawnY = _spawnBaseY - (_placedBlockCount * BlockHeightStep);
		nextBlock.SnapTo(_currentBlockSpawn.GlobalPosition.X, spawnY);
		nextBlock.SetHeight(BlockHeightStep);
		nextBlock.SetWidth(_referenceBlock.Width);
		nextBlock.SetBlockTexture(GetBlockTexture(_placedBlockCount + 1));
		nextBlock.SetBlockColor(GetBlockColor(_placedBlockCount + 1));
		nextBlock.StartMovement(_currentBlockSpawn.GlobalPosition.X, _activeLevel.BlockMoveSpeed, _activeLevel.HorizontalMoveRange, _placedBlockCount * 0.8f);

		_currentBlock = nextBlock;
	}

	private void PlaceCurrentBlock()
	{
		if (_currentBlock == null)
		{
			return;
		}

		var currentBlock = _currentBlock;
		_currentBlock = null;
		_tapHintLabel.Visible = false;

		currentBlock.StopMovement();

		var previousLeft = _referenceBlock.LeftX;
		var previousRight = _referenceBlock.RightX;
		var currentLeft = currentBlock.LeftX;
		var currentRight = currentBlock.RightX;
		var overlap = Mathf.Min(previousRight, currentRight) - Mathf.Max(previousLeft, currentLeft);

		if (overlap < _activeLevel.MinValidOverlap)
		{
			CreateFallingPiece(currentBlock.Width, currentBlock.CenterX, currentBlock.GlobalPosition.Y, currentBlock.BlockTexture, currentBlock.FillColor, currentBlock.CenterX >= _referenceBlock.CenterX ? 1.0f : -1.0f);
			currentBlock.QueueFree();
			EndLevel(false, overlap <= 0.0f ? "Missed the stack" : "Overlap too small");
			return;
		}

		var overlapLeft = Mathf.Max(previousLeft, currentLeft);
		var overlapRight = Mathf.Min(previousRight, currentRight);
		var overlapCenter = (overlapLeft + overlapRight) * 0.5f;
		var cutAmount = currentBlock.Width - overlap;

		CreateTrimmedOffcut(currentBlock, overlapLeft, overlapRight);

		currentBlock.SetWidth(overlap);
		currentBlock.SnapTo(overlapCenter, currentBlock.GlobalPosition.Y);

		_referenceBlock = currentBlock;
		_placedBlockCount++;

		_placeSoundPlayer.Play();
		PlayPlacementFeedback(currentBlock, cutAmount);
		UpdateProgressLabel();
		UpdateCamera();
		UpdateTowerDecor();

		if (_gameMode == GameMode.Level && _placedBlockCount >= _activeLevel.RequiredBlocksToWin)
		{
			GameProgress.CompleteCurrentLevel();
			CakeUnlockManager.TryUnlockForCompletedLevel(_activeLevelIndex + 1, out var unlockedVariant);
			var finalMessage = GameProgress.HasNextLevel(_activeLevelIndex) ? "Level cleared!" : "You finished every level!";
			EndLevel(true, finalMessage);
			if (unlockedVariant != null)
			{
				ShowUnlockPopup(unlockedVariant);
			}
			return;
		}

		SpawnNextBlock();
	}

	private void CreateTrimmedOffcut(MovingBlock originalBlock, float overlapLeft, float overlapRight)
	{
		var originalLeft = originalBlock.LeftX;
		var originalRight = originalBlock.RightX;
		var y = originalBlock.GlobalPosition.Y;

		var leftOffcutWidth = overlapLeft - originalLeft;
		if (leftOffcutWidth > 0.5f)
		{
			var centerX = originalLeft + (leftOffcutWidth * 0.5f);
			CreateFallingPiece(leftOffcutWidth, centerX, y, originalBlock.BlockTexture, originalBlock.FillColor, -1.0f);
		}

		var rightOffcutWidth = originalRight - overlapRight;
		if (rightOffcutWidth > 0.5f)
		{
			var centerX = overlapRight + (rightOffcutWidth * 0.5f);
			CreateFallingPiece(rightOffcutWidth, centerX, y, originalBlock.BlockTexture, originalBlock.FillColor, 1.0f);
		}
	}

	private void CreateFallingPiece(float width, float centerX, float centerY, Texture2D? texture, Color color, float horizontalDirection)
	{
		if (BlockScene == null)
		{
			return;
		}

		var fallingPiece = BlockScene.Instantiate<MovingBlock>();
		_placedBlocksRoot.AddChild(fallingPiece);

		fallingPiece.StopMovement();
		fallingPiece.SetHeight(BlockHeightStep);
		fallingPiece.SetWidth(width);
		fallingPiece.SetBlockTexture(texture);
		fallingPiece.SetBlockColor(color.Darkened(0.18f));
		fallingPiece.SnapTo(centerX, centerY);

		var tween = CreateTween();
		tween.SetParallel(true);
		tween.TweenProperty(fallingPiece, "position", fallingPiece.Position + new Vector2(CutHorizontalDrift * horizontalDirection, CutFallDistance), CutFallDuration)
			.SetTrans(Tween.TransitionType.Cubic)
			.SetEase(Tween.EaseType.In);
		tween.TweenProperty(fallingPiece, "rotation_degrees", 34.0f * horizontalDirection, CutFallDuration)
			.SetTrans(Tween.TransitionType.Cubic)
			.SetEase(Tween.EaseType.In);
		tween.TweenProperty(fallingPiece, "modulate:a", 0.1f, CutFallDuration)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.In);
		tween.Finished += fallingPiece.QueueFree;
	}

	private void PlayPlacementFeedback(MovingBlock placedBlock, float cutAmount)
	{
		var statusColor = Colors.White;
		var statusText = "Nice stack";
		var isPerfect = false;

		if (cutAmount <= PerfectPlacementThreshold)
		{
			statusColor = new Color(0.96f, 0.88f, 0.34f, 1.0f);
			statusText = "Perfect!";
			isPerfect = true;
		}
		else if (cutAmount <= NearPerfectPlacementThreshold)
		{
			statusColor = new Color(0.66f, 0.93f, 0.82f, 1.0f);
			statusText = "Great placement";
		}
		else
		{
			statusText = "Keep climbing";
		}

		_statusLabel.Text = statusText;
		_statusLabel.Modulate = statusColor;
		_tapHintLabel.Visible = true;
		_tapHintLabel.Text = "Tap again for the next block";
		PlayTowerBounce();
		EmitSprinkles(placedBlock.GlobalPosition);
		StartCameraShake(0.12f, 4.0f);
		if (isPerfect)
		{
			PlayPerfectLabel();
		}
	}

	private void EndLevel(bool won, string statusText)
	{
		_gameActive = false;
		_currentBlock = null;
		if (_gameMode == GameMode.Endless && !won)
		{
			var isNewRecord = GameProgress.TrySetBestEndlessScore(_placedBlockCount);
			_statusLabel.Text = isNewRecord
				? $"New best! Score {_placedBlockCount}"
				: $"Endless score: {_placedBlockCount}\nBest: {GameProgress.BestEndlessScore}";
		}
		else
		{
			_statusLabel.Text = won ? statusText : $"You lose! {statusText}";
		}

		_statusLabel.Modulate = won ? new Color(0.78f, 0.97f, 0.76f, 1.0f) : new Color(1.0f, 0.68f, 0.68f, 1.0f);
		_tapHintLabel.Visible = false;
		_resultSoundPlayer.Stream = won
			? ToneFactory.CreateGentleWinSound()
			: ToneFactory.CreateGentleLoseSound();
		_resultSoundPlayer.Play();

		_restartButton.Visible = true;
		_restartButton.Disabled = false;
		_restartButton.Text = _gameMode == GameMode.Endless ? "Restart Endless" : "Restart Level";

		var canGoNext = _gameMode == GameMode.Level && won && GameProgress.HasNextLevel(_activeLevelIndex);
		_nextLevelButton.Visible = canGoNext;
		_nextLevelButton.Disabled = !canGoNext;

		if (won)
		{
			PlayLevelCompleteLabel();
		}
	}

	private void UpdateProgressLabel()
	{
		_progressLabel.Text = _gameMode == GameMode.Endless
			? $"Score {_placedBlockCount}  Best {GameProgress.BestEndlessScore}"
			: $"Blocks {_placedBlockCount}/{_activeLevel.RequiredBlocksToWin}";
	}

	private void UpdateCamera()
	{
		var targetY = _cameraStartPosition.Y;
		var viewportSize = GetViewportRect().Size;
		var zoomY = Mathf.Max(_camera.Zoom.Y, 0.01f);
		var safeScreenY = _statusPanel.GetGlobalRect().End.Y + CameraUiSafePadding;
		var towerTopY = GetHighestBlockTopY();
		var requiredCameraY = towerTopY + ((viewportSize.Y * 0.5f) - safeScreenY) / zoomY;
		targetY = Mathf.Min(targetY, requiredCameraY);

		_cameraBasePosition = new Vector2(_cameraStartPosition.X, targetY);
		if (_cameraShakeTimeLeft <= 0.0f)
		{
			_camera.Position = _cameraBasePosition;
		}
	}

	private float GetHighestBlockTopY()
	{
		var topY = _referenceBlock.GlobalPosition.Y - (BlockHeightStep * 0.5f);
		if (_currentBlock != null)
		{
			topY = Mathf.Min(topY, _currentBlock.GlobalPosition.Y - (BlockHeightStep * 0.5f));
		}

		return topY;
	}

	private Color GetBlockColor(int index)
	{
		if (GetConfiguredBlockTextureCount() > 0)
		{
			return Colors.White;
		}

		return _blockColors[index % _blockColors.Length];
	}

	private Texture2D? GetBlockTexture(int index)
	{
		var variant = GetVariantForBlockIndex(index);
		var textures = variant.GetBlockTextures(_defaultBlockTextures);
		if (textures.Count == 0)
		{
			return null;
		}

		return textures[index % textures.Count];
	}

	private int GetConfiguredBlockTextureCount()
	{
		var variant = GetVariantForBlockIndex(_placedBlockCount);
		return variant.GetBlockTextures(_defaultBlockTextures).Count;
	}

	private void PlayTowerBounce()
	{
		var tween = CreateTween();
		tween.SetParallel(true);
		tween.TweenProperty(_placedBlocksRoot, "scale", new Vector2(1.0f, 0.92f), 0.07f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.Out);
		tween.TweenProperty(_basePlatform, "scale", new Vector2(1.0f, 0.96f), 0.07f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.Out);
		tween.TweenProperty(_towerShadow, "scale", new Vector2(_towerShadow.Scale.X * 1.06f, _towerShadow.Scale.Y * 1.12f), 0.07f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.Out);

		tween.Chain().SetParallel(true);
		tween.TweenProperty(_placedBlocksRoot, "scale", Vector2.One, 0.15f)
			.SetTrans(Tween.TransitionType.Bounce)
			.SetEase(Tween.EaseType.Out);
		tween.TweenProperty(_basePlatform, "scale", Vector2.One, 0.15f)
			.SetTrans(Tween.TransitionType.Bounce)
			.SetEase(Tween.EaseType.Out);
		tween.TweenProperty(_towerShadow, "scale", GetTowerShadowScale(), 0.15f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.Out);
	}

	private void EmitSprinkles(Vector2 worldPosition)
	{
		_sprinkleParticles.GlobalPosition = worldPosition + new Vector2(0.0f, -10.0f);
		_sprinkleParticles.Restart();
		_sprinkleParticles.Emitting = true;
	}

	private void StartCameraShake(float duration, float strength)
	{
		_cameraShakeTimeLeft = duration;
		_cameraShakeStrength = strength;
	}

	private void PlayPerfectLabel()
	{
		_perfectLabel.Visible = true;
		_perfectLabel.Scale = Vector2.Zero;
		_perfectLabel.Modulate = new Color(1.0f, 0.819608f, 0.4f, 1.0f);

		var tween = CreateTween();
		tween.SetParallel(true);
		tween.TweenProperty(_perfectLabel, "scale", new Vector2(1.2f, 1.2f), 0.12f)
			.SetTrans(Tween.TransitionType.Back)
			.SetEase(Tween.EaseType.Out);
		tween.Chain().TweenProperty(_perfectLabel, "scale", Vector2.One, 0.12f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.Out);
		tween.Chain().TweenProperty(_perfectLabel, "modulate:a", 0.0f, 0.8f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.In);
		tween.Finished += () => _perfectLabel.Visible = false;
	}

	private void PlayLevelCompleteLabel()
	{
		_levelCompleteLabel.Visible = true;
		_levelCompleteLabel.Scale = Vector2.Zero;
		_levelCompleteLabel.Modulate = new Color(1.0f, 0.819608f, 0.4f, 1.0f);

		var tween = CreateTween();
		tween.SetParallel(true);
		tween.TweenProperty(_levelCompleteLabel, "scale", new Vector2(1.2f, 1.2f), 0.16f)
			.SetTrans(Tween.TransitionType.Back)
			.SetEase(Tween.EaseType.Out);
		tween.Chain().TweenProperty(_levelCompleteLabel, "scale", Vector2.One, 0.12f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.Out);
		tween.Chain().TweenProperty(_levelCompleteLabel, "modulate:a", 0.0f, 1.0f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.In);
		tween.Finished += () => _levelCompleteLabel.Visible = false;
	}

	private void OnRestartPressed()
	{
		if (_gameMode == GameMode.Endless)
		{
			GameProgress.StartEndlessMode();
		}

		StartLevel();
	}

	private void OnNextLevelPressed()
	{
		if (_gameMode != GameMode.Level)
		{
			return;
		}

		if (!GameProgress.AdvanceToNextLevel())
		{
			return;
		}

		StartLevel();
	}

	private void OnBackToMenuPressed()
	{
		GetTree().ChangeSceneToFile("res://MainMenu.tscn");
	}

	private bool IsPointerOverButton(Vector2 screenPosition)
	{
		return IsPointerOverControl(_backToMenuButton, screenPosition) ||
			IsPointerOverControl(_restartButton, screenPosition) ||
			IsPointerOverControl(_nextLevelButton, screenPosition);
	}

	private static bool IsPointerOverControl(Button control, Vector2 screenPosition)
	{
		if (!control.Visible || control.Disabled)
		{
			return false;
		}

		return control.GetGlobalRect().HasPoint(screenPosition);
	}

	private void SetupDecorativeSprites()
	{
		_cakePlate.Texture = CreateCakePlateTexture(360, 118);
		_cakePlateShadow.Texture = CreateSoftEllipseTexture(320, 78, new Color(0.29f, 0.16f, 0.22f, 0.2f));
		_towerShadow.Texture = CreateSoftEllipseTexture(260, 70, new Color(0.29f, 0.16f, 0.22f, 0.15f));
		_towerShadow.Visible = false;
	}

	private void SetupBackgroundDecor()
	{
		_clouds.Clear();
		_cloudBaseOffsets.Clear();
		_cloudDriftSpeeds.Clear();

		var cloudLeft = GetNode<Polygon2D>("CloudLeft");
		var cloudRight = GetNode<Polygon2D>("CloudRight");
		_clouds.Add(cloudLeft);
		_cloudBaseOffsets.Add(cloudLeft.Position);
		_cloudDriftSpeeds.Add(8.0f);
		_clouds.Add(cloudRight);
		_cloudBaseOffsets.Add(cloudRight.Position);
		_cloudDriftSpeeds.Add(-10.0f);

		for (var i = 0; i < 4; i++)
		{
			var cloud = CreateCloudPolygon(i % 2 == 0 ? 0.28f : 0.22f);
			AddChild(cloud);
			MoveChild(cloud, 4 + i);
			_clouds.Add(cloud);
			_cloudBaseOffsets.Add(CreateCloudOffset(i));
			_cloudDriftSpeeds.Add(_random.RandfRange(-14.0f, 14.0f));
		}

		_highestCloudAnchorY = 0.0f;
	}

	private void ConfigureSprinkleParticles()
	{
		_sprinkleParticles.Texture = CreateSprinkleTexture(12, 4);
		_sprinkleParticles.Amount = 18;
		_sprinkleParticles.Lifetime = 0.7f;
		_sprinkleParticles.OneShot = true;
		_sprinkleParticles.Explosiveness = 1.0f;
		_sprinkleParticles.Direction = Vector2.Down;
		_sprinkleParticles.Spread = 40.0f;
		_sprinkleParticles.Gravity = new Vector2(0.0f, 420.0f);
		_sprinkleParticles.InitialVelocityMin = 70.0f;
		_sprinkleParticles.InitialVelocityMax = 120.0f;
		_sprinkleParticles.ScaleAmountMin = 0.85f;
		_sprinkleParticles.ScaleAmountMax = 1.25f;
		_sprinkleParticles.ColorRamp = CreateSprinkleGradient();
	}

	private void UpdateTowerDecor()
	{
		_cakePlate.GlobalPosition = _basePlatform.GlobalPosition + new Vector2(0.0f, BlockHeightStep * 0.66f);
		_cakePlateShadow.GlobalPosition = _cakePlate.GlobalPosition + new Vector2(0.0f, 24.0f);
		_cakePlate.Scale = new Vector2(Mathf.Max((_activeLevel.InitialBlockWidth + 130.0f) / 360.0f, 1.15f), 1.08f);
		_cakePlateShadow.Scale = new Vector2(_cakePlate.Scale.X * 1.1f, 0.34f);
		_towerShadow.GlobalPosition = _basePlatform.GlobalPosition + new Vector2(0.0f, BlockHeightStep * 0.92f);
		_towerShadow.Scale = GetTowerShadowScale();
	}

	private void ResetBackgroundVisuals()
	{
		_highestCloudAnchorY = _cameraBasePosition.Y;
		for (var i = 0; i < _clouds.Count; i++)
		{
			var baseOffset = _cloudBaseOffsets[i];
			_clouds[i].Position = new Vector2(baseOffset.X, _cameraBasePosition.Y + baseOffset.Y);
		}

		UpdateBackgroundVisuals();
	}

	private void UpdateBackgroundVisuals()
	{
		var viewportSize = GetViewportRect().Size;
		var zoomX = Mathf.Max(_camera.Zoom.X, 0.01f);
		var zoomY = Mathf.Max(_camera.Zoom.Y, 0.01f);
		var visibleWorldWidth = viewportSize.X / zoomX;
		var visibleWorldHeight = viewportSize.Y / zoomY;
		var halfWidth = Mathf.Max((visibleWorldWidth * 0.5f) + 140.0f, 520.0f);
		var topHeight = Mathf.Max(visibleWorldHeight * 0.72f, 820.0f);
		var bottomHeight = Mathf.Max(visibleWorldHeight * 1.05f, 980.0f);
		var cameraY = _camera.Position.Y;
		_backdropTop.Position = new Vector2(-halfWidth, cameraY - topHeight);
		_backdropTop.Size = new Vector2(halfWidth * 2.0f, topHeight + 420.0f);
		_backdropBottom.Position = new Vector2(-halfWidth, cameraY - 40.0f);
		_backdropBottom.Size = new Vector2(halfWidth * 2.0f, bottomHeight);

		for (var i = 0; i < _clouds.Count; i++)
		{
			var cloud = _clouds[i];
			var driftedBase = _cloudBaseOffsets[i];
			driftedBase.X += _cloudDriftSpeeds[i] * (float)GetProcessDeltaTime();
			var horizontalLimit = halfWidth + 180.0f;
			if (driftedBase.X > horizontalLimit)
			{
				driftedBase.X = -horizontalLimit;
			}
			else if (driftedBase.X < -horizontalLimit)
			{
				driftedBase.X = horizontalLimit;
			}
			_cloudBaseOffsets[i] = driftedBase;

			var parallaxY = cameraY * (0.35f + (i * 0.04f));
			var targetY = parallaxY + driftedBase.Y;

			if (targetY > cameraY + 120.0f)
			{
				_cloudBaseOffsets[i] = new Vector2(
					_random.RandfRange(-300.0f, 300.0f),
					_highestCloudAnchorY - _random.RandfRange(180.0f, 320.0f));
				_cloudDriftSpeeds[i] = _random.RandfRange(-14.0f, 14.0f);
				_highestCloudAnchorY = _cloudBaseOffsets[i].Y;
				cloud.Position = _cloudBaseOffsets[i];
				cloud.Rotation = _random.RandfRange(-0.16f, 0.16f);
				cloud.Scale = Vector2.One * _random.RandfRange(0.9f, 1.15f);
				continue;
			}

			cloud.Position = new Vector2(_cloudBaseOffsets[i].X, targetY);
		}
	}

	private Vector2 GetTowerShadowScale()
	{
		var widthScale = Mathf.Max((_activeLevel.InitialBlockWidth + (_placedBlockCount * 6.0f)) / 260.0f, 0.9f);
		return new Vector2(widthScale, 0.34f);
	}

	private void ApplyResponsiveUi(Vector2 viewportSize)
	{
		var compact = viewportSize.X < 550.0f;
		var ultraCompact = viewportSize.X < 430.0f;

		_topPanel.AnchorLeft = compact ? 0.03f : 0.04f;
		_topPanel.AnchorRight = compact ? 0.97f : 0.96f;
		_topPanel.AnchorTop = 0.03f;
		_topPanel.AnchorBottom = compact ? 0.205f : 0.16f;
		_statusPanel.AnchorLeft = compact ? 0.05f : 0.08f;
		_statusPanel.AnchorRight = compact ? 0.95f : 0.92f;
		_statusPanel.AnchorTop = compact ? 0.255f : 0.18f;
		_statusPanel.AnchorBottom = compact ? 0.35f : 0.26f;
		_actionButtons.AnchorLeft = compact ? 0.05f : 0.08f;
		_actionButtons.AnchorRight = compact ? 0.95f : 0.92f;

		_topPanelMargin.AddThemeConstantOverride("margin_left", compact ? 12 : 18);
		_topPanelMargin.AddThemeConstantOverride("margin_top", compact ? 12 : 16);
		_topPanelMargin.AddThemeConstantOverride("margin_right", compact ? 12 : 18);
		_topPanelMargin.AddThemeConstantOverride("margin_bottom", compact ? 12 : 16);
		_topRow.AddThemeConstantOverride("separation", compact ? 8 : 12);
		_actionButtons.AddThemeConstantOverride("separation", compact ? 10 : 16);

		_levelLabel.AddThemeFontSizeOverride("font_size", ultraCompact ? 18 : compact ? 20 : 24);
		_progressLabel.AddThemeFontSizeOverride("font_size", ultraCompact ? 15 : compact ? 17 : 20);
		_statusLabel.AddThemeFontSizeOverride("font_size", ultraCompact ? 18 : compact ? 20 : 22);
		_tapHintLabel.AddThemeFontSizeOverride("font_size", ultraCompact ? 16 : compact ? 18 : 20);
		_perfectLabel.AddThemeFontSizeOverride("font_size", ultraCompact ? 42 : compact ? 46 : 52);
		_levelCompleteLabel.AddThemeFontSizeOverride("font_size", ultraCompact ? 48 : compact ? 54 : 62);

		_backToMenuButton.CustomMinimumSize = new Vector2(ultraCompact ? 118.0f : compact ? 132.0f : 170.0f, compact ? 48.0f : 56.0f);
		_backToMenuButton.AddThemeFontSizeOverride("font_size", ultraCompact ? 14 : compact ? 16 : 20);
		_restartButton.CustomMinimumSize = new Vector2(0.0f, compact ? 58.0f : 64.0f);
		_nextLevelButton.CustomMinimumSize = new Vector2(0.0f, compact ? 58.0f : 64.0f);
		_restartButton.AddThemeFontSizeOverride("font_size", ultraCompact ? 18 : compact ? 20 : 22);
		_nextLevelButton.AddThemeFontSizeOverride("font_size", ultraCompact ? 18 : compact ? 20 : 22);

		_perfectLabel.OffsetLeft = compact ? 120.0f : 250.0f;
		_perfectLabel.OffsetRight = compact ? viewportSize.X - 120.0f : 470.0f;
		_levelCompleteLabel.OffsetLeft = compact ? 36.0f : 180.0f;
		_levelCompleteLabel.OffsetRight = compact ? viewportSize.X - 36.0f : 540.0f;
		PositionUnlockPopup(viewportSize, compact);
	}

	private void BuildDefaultTextureList()
	{
		_defaultBlockTextures.Clear();
		AddDefaultTexture(BlockTexture1);
		AddDefaultTexture(BlockTexture2);
		AddDefaultTexture(BlockTexture3);
		AddDefaultTexture(BlockTexture4);
	}

	private void AddDefaultTexture(Texture2D? texture)
	{
		if (texture != null)
		{
			_defaultBlockTextures.Add(texture);
		}
	}

	private void ShowUnlockPopup(CakeVariantConfig unlockedVariant)
	{
		_unlockPopupLabel.Text = $"New Cake Style Unlocked!\n{unlockedVariant.DisplayName}";
		_unlockPopupPreview.Texture = unlockedVariant.GetPreviewTexture(_defaultBlockTextures);
		PositionUnlockPopup(_lastViewportSize, _lastViewportSize.X < 550.0f);
		_unlockPopup.Visible = true;
		_unlockPopup.Scale = Vector2.One * 0.8f;
		_unlockPopup.Modulate = new Color(1.0f, 1.0f, 1.0f, 0.0f);

		var tween = CreateTween();
		tween.SetParallel(true);
		tween.TweenProperty(_unlockPopup, "scale", new Vector2(1.05f, 1.05f), 0.18f)
			.SetTrans(Tween.TransitionType.Back)
			.SetEase(Tween.EaseType.Out);
		tween.TweenProperty(_unlockPopup, "modulate:a", 1.0f, 0.16f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.Out);
		tween.Chain().TweenProperty(_unlockPopup, "scale", Vector2.One, 0.12f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.Out);
		tween.Chain().TweenInterval(1.6f);
		tween.Chain().TweenProperty(_unlockPopup, "modulate:a", 0.0f, 0.4f)
			.SetTrans(Tween.TransitionType.Quad)
			.SetEase(Tween.EaseType.In);
		tween.Finished += () => _unlockPopup.Visible = false;
	}

	private void PositionUnlockPopup(Vector2 viewportSize, bool compact)
	{
		var popupWidth = Mathf.Min(compact ? viewportSize.X - 48.0f : 320.0f, viewportSize.X - 32.0f);
		var popupHeight = compact ? 150.0f : 184.0f;
		var popupLeft = (viewportSize.X - popupWidth) * 0.5f;
		var actionButtonsTop = _actionButtons.GetGlobalRect().Position.Y;
		var popupTop = Mathf.Max(24.0f, actionButtonsTop - popupHeight - 18.0f);

		_unlockPopup.AnchorLeft = 0.0f;
		_unlockPopup.AnchorTop = 0.0f;
		_unlockPopup.AnchorRight = 0.0f;
		_unlockPopup.AnchorBottom = 0.0f;
		_unlockPopup.OffsetLeft = popupLeft;
		_unlockPopup.OffsetTop = popupTop;
		_unlockPopup.OffsetRight = popupLeft + popupWidth;
		_unlockPopup.OffsetBottom = popupTop + popupHeight;
	}

	private CakeVariantConfig GetVariantForBlockIndex(int blockIndex)
	{
		if (_unlockedCakeVariants.Count == 0)
		{
			_unlockedCakeVariants = CakeUnlockManager.GetUnlockedVariants();
		}

		return _unlockedCakeVariants[blockIndex % _unlockedCakeVariants.Count];
	}

	private static Texture2D CreateSoftEllipseTexture(int width, int height, Color color)
	{
		var image = Image.CreateEmpty(width, height, false, Image.Format.Rgba8);
		var center = new Vector2((width - 1) * 0.5f, (height - 1) * 0.5f);
		var rx = width * 0.5f;
		var ry = height * 0.5f;

		for (var y = 0; y < height; y++)
		{
			for (var x = 0; x < width; x++)
			{
				var dx = (x - center.X) / rx;
				var dy = (y - center.Y) / ry;
				var distance = Mathf.Sqrt((dx * dx) + (dy * dy));
				if (distance > 1.0f)
				{
					image.SetPixel(x, y, Colors.Transparent);
					continue;
				}

				var alpha = color.A * Mathf.Clamp((1.0f - distance) / 0.35f, 0.0f, 1.0f);
				image.SetPixel(x, y, new Color(color.R, color.G, color.B, alpha));
			}
		}

		return ImageTexture.CreateFromImage(image);
	}

	private static Texture2D CreateCakePlateTexture(int width, int height)
	{
		var image = Image.CreateEmpty(width, height, false, Image.Format.Rgba8);
		var undersideColor = new Color(0.84f, 0.73f, 0.79f, 0.45f);
		var standColor = new Color(0.86f, 0.74f, 0.80f, 0.95f);

		// Keep only a soft lower saucer and pedestal so the bright top oval does not show around the cake.
		DrawFilledEllipse(image, new Rect2(24, 26, width - 48, 18), undersideColor);
		DrawRoundedRect(image, new Rect2((width * 0.5f) - 34.0f, 48.0f, 68.0f, 28.0f), 12, standColor);
		DrawFilledEllipse(image, new Rect2((width * 0.5f) - 68.0f, 68.0f, 136.0f, 24.0f), standColor.Darkened(0.08f));

		return ImageTexture.CreateFromImage(image);
	}

	private static Texture2D CreateSprinkleTexture(int width, int height)
	{
		var image = Image.CreateEmpty(width, height, false, Image.Format.Rgba8);
		DrawRoundedRect(image, new Rect2(0, 0, width, height), 2, Colors.White);
		return ImageTexture.CreateFromImage(image);
	}

	private static Gradient CreateSprinkleGradient()
	{
		var gradient = new Gradient();
		gradient.Offsets = new[] { 0.0f, 0.33f, 0.66f, 1.0f };
		gradient.Colors = new[]
		{
			new Color("FFD166"),
			new Color("FF8FAB"),
			new Color("7BDFF2"),
			new Color("F4A261")
		};

		return gradient;
	}

	private Polygon2D CreateCloudPolygon(float alpha)
	{
		var cloud = new Polygon2D();
		cloud.Color = new Color(1.0f, 1.0f, 1.0f, alpha);
		cloud.Polygon = new[]
		{
			new Vector2(-120.0f, 4.0f),
			new Vector2(-80.0f, -30.0f),
			new Vector2(-24.0f, -20.0f),
			new Vector2(10.0f, -54.0f),
			new Vector2(86.0f, -18.0f),
			new Vector2(130.0f, 4.0f),
			new Vector2(88.0f, 24.0f),
			new Vector2(-94.0f, 28.0f)
		};
		return cloud;
	}

	private Vector2 CreateCloudOffset(int index)
	{
		return new Vector2(
			index % 2 == 0 ? -240.0f : 230.0f,
			-260.0f - (index * 170.0f));
	}

	private static void DrawFilledEllipse(Image image, Rect2 rect, Color color)
	{
		var center = rect.Position + (rect.Size * 0.5f);
		var rx = rect.Size.X * 0.5f;
		var ry = rect.Size.Y * 0.5f;

		for (var y = Mathf.FloorToInt(rect.Position.Y); y < Mathf.CeilToInt(rect.End.Y); y++)
		{
			for (var x = Mathf.FloorToInt(rect.Position.X); x < Mathf.CeilToInt(rect.End.X); x++)
			{
				var dx = (x - center.X) / rx;
				var dy = (y - center.Y) / ry;
				if ((dx * dx) + (dy * dy) <= 1.0f)
				{
					image.SetPixel(x, y, color);
				}
			}
		}
	}

	private static void DrawRoundedRect(Image image, Rect2 rect, int radius, Color color)
	{
		for (var y = Mathf.FloorToInt(rect.Position.Y); y < Mathf.CeilToInt(rect.End.Y); y++)
		{
			for (var x = Mathf.FloorToInt(rect.Position.X); x < Mathf.CeilToInt(rect.End.X); x++)
			{
				var localX = x - rect.Position.X;
				var localY = y - rect.Position.Y;
				var insideCore = localX >= radius && localX <= rect.Size.X - radius;
				insideCore |= localY >= radius && localY <= rect.Size.Y - radius;
				if (insideCore)
				{
					image.SetPixel(x, y, color);
					continue;
				}

				var cornerX = localX < radius ? radius : rect.Size.X - radius;
				var cornerY = localY < radius ? radius : rect.Size.Y - radius;
				var dx = localX - cornerX;
				var dy = localY - cornerY;
				if ((dx * dx) + (dy * dy) <= radius * radius)
				{
					image.SetPixel(x, y, color);
				}
			}
		}
	}
}
