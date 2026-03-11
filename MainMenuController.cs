using Godot;
using System.Collections.Generic;

public partial class MainMenuController : Control
{
	private Label _subtitleLabel = null!;
	private VBoxContainer _menuButtons = null!;
	private Vector2 _lastViewportSize;
	private Button _playButton = null!;
	private Button _startGameButton = null!;
	private Button _settingsButton = null!;
	private Button _levelSelectButton = null!;
	private Button _endlessModeButton = null!;
	private Button _privacyPolicyButton = null!;
	private Button _quitButton = null!;
	private AudioStreamPlayer _uiSoundPlayer = null!;
	private Control _settingsOverlay = null!;
	private CheckButton _soundToggle = null!;
	private Label _volumeLabel = null!;
	private HSlider _volumeSlider = null!;
	private Button _resetCakeStylesButton = null!;
	private Button _settingsBackButton = null!;
	private Control _privacyOverlay = null!;
	private PanelContainer _privacyPanel = null!;
	private MarginContainer _privacyMargin = null!;
	private Label _privacyTitleLabel = null!;
	private ScrollContainer _privacyBodyScroll = null!;
	private Label _privacyBodyLabel = null!;
	private Button _privacyBackButton = null!;
	private Control _levelSelectOverlay = null!;
	private PanelContainer _levelSelectPanel = null!;
	private MarginContainer _levelSelectMargin = null!;
	private Label _levelSelectTitleLabel = null!;
	private GridContainer _levelGrid = null!;
	private Button _levelSelectBackButton = null!;
	private readonly List<Button> _levelButtons = new();

	public override void _Ready()
	{
		_subtitleLabel = GetNode<Label>("MenuPanel/Margin/Content/SubtitleLabel");
		_menuButtons = GetNode<VBoxContainer>("MenuPanel/Margin/Content/MenuButtons");
		_playButton = GetNode<Button>("MenuPanel/Margin/Content/MenuButtons/PlayButton");
		_startGameButton = GetNode<Button>("MenuPanel/Margin/Content/UtilityButtons/StartGameButton");
		_settingsButton = GetNode<Button>("MenuPanel/Margin/Content/UtilityButtons/SettingsButton");
		_levelSelectButton = GetNode<Button>("MenuPanel/Margin/Content/MenuButtons/LevelSelectButton");
		_endlessModeButton = GetNode<Button>("MenuPanel/Margin/Content/MenuButtons/EndlessModeButton");
		_privacyPolicyButton = GetNode<Button>("MenuPanel/Margin/Content/UtilityButtons/PrivacyPolicyButton");
		_quitButton = GetNode<Button>("MenuPanel/Margin/Content/UtilityButtons/QuitButton");
		_uiSoundPlayer = GetNode<AudioStreamPlayer>("UiSoundPlayer");
		_settingsOverlay = GetNode<Control>("SettingsOverlay");
		_soundToggle = GetNode<CheckButton>("SettingsOverlay/SettingsPanel/Margin/Content/SoundToggle");
		_volumeLabel = GetNode<Label>("SettingsOverlay/SettingsPanel/Margin/Content/VolumeLabel");
		_volumeSlider = GetNode<HSlider>("SettingsOverlay/SettingsPanel/Margin/Content/VolumeSlider");
		_resetCakeStylesButton = GetNode<Button>("SettingsOverlay/SettingsPanel/Margin/Content/ResetCakeStylesButton");
		_settingsBackButton = GetNode<Button>("SettingsOverlay/SettingsPanel/Margin/Content/BackButton");
		_privacyOverlay = GetNode<Control>("PrivacyOverlay");
		_privacyPanel = GetNode<PanelContainer>("PrivacyOverlay/PrivacyPanel");
		_privacyMargin = GetNode<MarginContainer>("PrivacyOverlay/PrivacyPanel/Margin");
		_privacyTitleLabel = GetNode<Label>("PrivacyOverlay/PrivacyPanel/Margin/Content/TitleLabel");
		_privacyBodyScroll = GetNode<ScrollContainer>("PrivacyOverlay/PrivacyPanel/Margin/Content/BodyScroll");
		_privacyBodyLabel = GetNode<Label>("PrivacyOverlay/PrivacyPanel/Margin/Content/BodyScroll/BodyLabel");
		_privacyBackButton = GetNode<Button>("PrivacyOverlay/PrivacyPanel/Margin/Content/BackButton");
		_levelSelectOverlay = GetNode<Control>("LevelSelectOverlay");
		_levelSelectPanel = GetNode<PanelContainer>("LevelSelectOverlay/LevelSelectPanel");
		_levelSelectMargin = GetNode<MarginContainer>("LevelSelectOverlay/LevelSelectPanel/Margin");
		_levelSelectTitleLabel = GetNode<Label>("LevelSelectOverlay/LevelSelectPanel/Margin/Content/TitleLabel");
		_levelGrid = GetNode<GridContainer>("LevelSelectOverlay/LevelSelectPanel/Margin/Content/LevelGrid");
		_levelSelectBackButton = GetNode<Button>("LevelSelectOverlay/LevelSelectPanel/Margin/Content/BackButton");

		_playButton.Pressed += OnPlayPressed;
		_startGameButton.Pressed += OnStartGamePressed;
		_settingsButton.Pressed += OnSettingsPressed;
		_levelSelectButton.Pressed += OnLevelSelectPressed;
		_endlessModeButton.Pressed += OnEndlessModePressed;
		_privacyPolicyButton.Pressed += OnPrivacyPolicyPressed;
		_quitButton.Pressed += OnQuitPressed;
		_soundToggle.Toggled += OnSoundToggled;
		_volumeSlider.ValueChanged += OnVolumeChanged;
		_resetCakeStylesButton.Pressed += OnResetCakeStylesPressed;
		_settingsBackButton.Pressed += OnSettingsBackPressed;
		_privacyBackButton.Pressed += OnPrivacyBackPressed;
		_levelSelectBackButton.Pressed += OnLevelSelectBackPressed;

		_uiSoundPlayer.Stream = ToneFactory.CreateMenuClickSound();

		AppSettings.EnsureLoaded();
		GameProgress.EnsureLoaded();
		CakeUnlockManager.EnsureLoaded();
		_lastViewportSize = GetViewportRect().Size;

		_soundToggle.ButtonPressed = AppSettings.SoundEnabled;
		_volumeSlider.Value = Mathf.RoundToInt(AppSettings.Volume * 100.0f);
		BuildLevelButtons();
		RefreshSoundToggleText();
		RefreshVolumeText();
		RefreshMenuText();
		ApplyResponsiveLayout(_lastViewportSize);
	}

	public override void _Process(double delta)
	{
		var viewportSize = GetViewportRect().Size;
		if (viewportSize == _lastViewportSize)
		{
			return;
		}

		_lastViewportSize = viewportSize;
		ApplyResponsiveLayout(viewportSize);
	}

	private void RefreshMenuText()
	{
		var unlockedLevelNumber = GameProgress.HighestUnlockedLevelIndex + 1;
		_subtitleLabel.Text = $"Unlocked: Level {unlockedLevelNumber}/{GameProgress.TotalLevels}";
		_playButton.Text = $"Play Level {unlockedLevelNumber}";
		_startGameButton.Text = "Start From Level 1";
		RefreshEndlessButtonLayout();
		RefreshLevelButtons();
	}

	private void RefreshEndlessButtonLayout()
	{
		var endlessUnlocked = GameProgress.EndlessModeUnlocked;
		var isInMenuButtons = _endlessModeButton.GetParent() == _menuButtons;

		if (endlessUnlocked && !isInMenuButtons)
		{
			var currentParent = _endlessModeButton.GetParent();
			currentParent?.RemoveChild(_endlessModeButton);
			_menuButtons.AddChild(_endlessModeButton);
			_menuButtons.MoveChild(_endlessModeButton, 2);
		}
		else if (!endlessUnlocked && isInMenuButtons)
		{
			_menuButtons.RemoveChild(_endlessModeButton);
		}

		_endlessModeButton.Visible = endlessUnlocked;
		_endlessModeButton.Disabled = !endlessUnlocked;
	}

	private void RefreshSoundToggleText()
	{
		_soundToggle.Text = AppSettings.SoundEnabled ? "Sound: ON" : "Sound: OFF";
	}

	private void RefreshVolumeText()
	{
		_volumeLabel.Text = $"Volume: {Mathf.RoundToInt(AppSettings.Volume * 100.0f)}%";
	}

	private void PlayUiSound()
	{
		_uiSoundPlayer.Play();
	}

	private void OnPlayPressed()
	{
		PlayUiSound();
		GameProgress.ContinueGame();
		GetTree().ChangeSceneToFile("res://Game.tscn");
	}

	private void OnStartGamePressed()
	{
		PlayUiSound();
		GameProgress.StartGame();
		GetTree().ChangeSceneToFile("res://Game.tscn");
	}

	private void OnSettingsPressed()
	{
		PlayUiSound();
		_settingsOverlay.Visible = true;
		_privacyOverlay.Visible = false;
		_levelSelectOverlay.Visible = false;
	}

	private void OnLevelSelectPressed()
	{
		PlayUiSound();
		RefreshLevelButtons();
		_levelSelectOverlay.Visible = true;
		_settingsOverlay.Visible = false;
		_privacyOverlay.Visible = false;
	}

	private void OnEndlessModePressed()
	{
		PlayUiSound();
		GameProgress.StartEndlessMode();
		GetTree().ChangeSceneToFile("res://Game.tscn");
	}

	private void OnPrivacyPolicyPressed()
	{
		PlayUiSound();
		_privacyOverlay.Visible = true;
		_settingsOverlay.Visible = false;
		_levelSelectOverlay.Visible = false;
	}

	private void OnQuitPressed()
	{
		PlayUiSound();
		GetTree().Quit();
	}

	private void OnSoundToggled(bool buttonPressed)
	{
		AppSettings.SetSoundEnabled(buttonPressed);
		RefreshSoundToggleText();
	}

	private void OnVolumeChanged(double value)
	{
		AppSettings.SetVolume((float)value / 100.0f);
		RefreshVolumeText();
	}

	private void OnSettingsBackPressed()
	{
		PlayUiSound();
		_settingsOverlay.Visible = false;
	}

	private void OnResetCakeStylesPressed()
	{
		PlayUiSound();
		CakeUnlockManager.ResetUnlockedVariants();
	}

	private void OnPrivacyBackPressed()
	{
		PlayUiSound();
		_privacyOverlay.Visible = false;
	}

	private void OnLevelSelectBackPressed()
	{
		PlayUiSound();
		_levelSelectOverlay.Visible = false;
	}

	private void BuildLevelButtons()
	{
		foreach (var child in _levelGrid.GetChildren())
		{
			child.QueueFree();
		}

		_levelButtons.Clear();

		for (var i = 0; i < GameProgress.TotalLevels; i++)
		{
			var levelIndex = i;
			var button = new Button
			{
				CustomMinimumSize = new Vector2(0.0f, 64.0f),
				Text = $"Level {levelIndex + 1}"
			};
			button.Pressed += () => OnLevelButtonPressed(levelIndex);
			_levelGrid.AddChild(button);
			_levelButtons.Add(button);
		}
	}

	private void RefreshLevelButtons()
	{
		for (var i = 0; i < _levelButtons.Count; i++)
		{
			var unlocked = i <= GameProgress.HighestUnlockedLevelIndex;
			_levelButtons[i].Visible = true;
			_levelButtons[i].Disabled = !unlocked;
			_levelButtons[i].Text = unlocked ? $"Level {i + 1}" : $"Locked {i + 1}";
		}

		ApplyResponsiveLayout(_lastViewportSize);
	}

	private void OnLevelButtonPressed(int levelIndex)
	{
		if (levelIndex > GameProgress.HighestUnlockedLevelIndex)
		{
			return;
		}

		PlayUiSound();
		GameProgress.SetCurrentLevel(levelIndex);
		GetTree().ChangeSceneToFile("res://Game.tscn");
	}

	private void ApplyResponsiveLayout(Vector2 viewportSize)
	{
		ApplyPrivacyResponsiveLayout(viewportSize);
		ApplyLevelSelectResponsiveLayout(viewportSize);
	}

	private void ApplyPrivacyResponsiveLayout(Vector2 viewportSize)
	{
		var compact = viewportSize.X < 430.0f;
		var narrow = viewportSize.X < 520.0f;
		var shortScreen = viewportSize.Y < 760.0f;

		_privacyPanel.AnchorLeft = narrow ? 0.03f : 0.08f;
		_privacyPanel.AnchorRight = narrow ? 0.97f : 0.92f;
		_privacyPanel.AnchorTop = shortScreen ? 0.05f : 0.1f;
		_privacyPanel.AnchorBottom = shortScreen ? 0.95f : 0.9f;
		_privacyPanel.OffsetLeft = 0.0f;
		_privacyPanel.OffsetTop = 0.0f;
		_privacyPanel.OffsetRight = 0.0f;
		_privacyPanel.OffsetBottom = 0.0f;

		var margin = compact ? 14 : narrow ? 18 : 24;
		_privacyMargin.AddThemeConstantOverride("margin_left", margin);
		_privacyMargin.AddThemeConstantOverride("margin_top", margin);
		_privacyMargin.AddThemeConstantOverride("margin_right", margin);
		_privacyMargin.AddThemeConstantOverride("margin_bottom", margin);

		_privacyTitleLabel.AddThemeFontSizeOverride("font_size", compact ? 24 : 30);
		_privacyBodyLabel.AddThemeFontSizeOverride("font_size", compact ? 18 : 22);
		_privacyBackButton.CustomMinimumSize = new Vector2(0.0f, compact ? 60.0f : 68.0f);
		_privacyBackButton.AddThemeFontSizeOverride("font_size", compact ? 24 : 28);

		var availableWidth = (viewportSize.X * (_privacyPanel.AnchorRight - _privacyPanel.AnchorLeft)) - (margin * 2.0f);
		_privacyBodyLabel.CustomMinimumSize = new Vector2(Mathf.Max(availableWidth - 12.0f, 220.0f), 0.0f);
		_privacyBodyScroll.CustomMinimumSize = new Vector2(0.0f, shortScreen ? 260.0f : 320.0f);
	}

	private void ApplyLevelSelectResponsiveLayout(Vector2 viewportSize)
	{
		var compact = viewportSize.X < 430.0f;
		var narrow = viewportSize.X < 520.0f;
		var veryShort = viewportSize.Y < 760.0f;

		_levelSelectPanel.AnchorLeft = narrow ? 0.03f : 0.06f;
		_levelSelectPanel.AnchorRight = narrow ? 0.97f : 0.94f;
		_levelSelectPanel.AnchorTop = veryShort ? 0.08f : 0.12f;
		_levelSelectPanel.AnchorBottom = veryShort ? 0.94f : 0.88f;
		_levelSelectPanel.OffsetLeft = 0.0f;
		_levelSelectPanel.OffsetTop = 0.0f;
		_levelSelectPanel.OffsetRight = 0.0f;
		_levelSelectPanel.OffsetBottom = 0.0f;

		var margin = compact ? 14 : narrow ? 18 : 22;
		_levelSelectMargin.AddThemeConstantOverride("margin_left", margin);
		_levelSelectMargin.AddThemeConstantOverride("margin_top", margin);
		_levelSelectMargin.AddThemeConstantOverride("margin_right", margin);
		_levelSelectMargin.AddThemeConstantOverride("margin_bottom", margin);

		_levelSelectTitleLabel.AddThemeFontSizeOverride("font_size", compact ? 24 : 30);
		_levelGrid.Columns = compact ? 2 : 3;
		_levelGrid.AddThemeConstantOverride("h_separation", compact ? 10 : 14);
		_levelGrid.AddThemeConstantOverride("v_separation", compact ? 10 : 14);
		_levelSelectBackButton.CustomMinimumSize = new Vector2(0.0f, compact ? 60.0f : 68.0f);
		_levelSelectBackButton.AddThemeFontSizeOverride("font_size", compact ? 24 : 28);

		for (var i = 0; i < _levelButtons.Count; i++)
		{
			var button = _levelButtons[i];
			button.CustomMinimumSize = new Vector2(0.0f, compact ? 54.0f : 64.0f);
			button.AddThemeFontSizeOverride("font_size", compact ? 18 : 22);
		}
	}
}
