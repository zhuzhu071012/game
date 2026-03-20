using System;
using System.IO;
using Godot;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.UI;

public partial class MainMenu : Control
{
	private TextureRect _cover = null!;
	private Label _gameTitleLabel = null!;
	private Label _subtitleLabel = null!;
	private Label _noticeLabel = null!;
	private Label _statusLabel = null!;
	private Button _newGameButton = null!;
	private Button _loadGameButton = null!;
	private SaveManager _saveManager = null!;

	public override void _Ready()
	{
		UiThemeHelper.ApplyChineseTheme(this);
		_cover = GetNode<TextureRect>("Backdrop/CoverArt");
		_gameTitleLabel = GetNode<Label>("Overlay/Margin/Panel/Content/GameTitle");
		_subtitleLabel = GetNode<Label>("Overlay/Margin/Panel/Content/Subtitle");
		_noticeLabel = GetNode<Label>("Overlay/Margin/Panel/Content/Notice");
		_statusLabel = GetNode<Label>("Overlay/Margin/Panel/Content/Status");
		_newGameButton = GetNode<Button>("Overlay/Margin/Panel/Content/Buttons/NewGame");
		_loadGameButton = GetNode<Button>("Overlay/Margin/Panel/Content/Buttons/LoadGame");
		_saveManager = new SaveManager();

		LoadCover();
		ApplyStaticTexts();
		UpdateStatus();
	}

	private void LoadCover()
	{
		var titlePath = Path.Combine(ResolveOriginalResourceRoot(), "TITLE.png");
		if (!File.Exists(titlePath))
		{
			return;
		}

		var image = new Image();
		var error = image.Load(titlePath);
		if (error != Error.Ok)
		{
			GD.PushWarning($"Failed to load title cover: {titlePath}");
			return;
		}

		_cover.Texture = ImageTexture.CreateFromImage(image);
	}

	private void ApplyStaticTexts()
	{
		_gameTitleLabel.Text = TextDb.Ui("main_menu.title");
		_subtitleLabel.Text = TextDb.Ui("main_menu.subtitle");
		_noticeLabel.Text = TextDb.Ui("main_menu.notice");
		_newGameButton.Text = TextDb.Ui("main_menu.new_game");
		_loadGameButton.Text = TextDb.Ui("main_menu.load_game");
		_statusLabel.Text = TextDb.Ui("main_menu.loading");
	}

	private void UpdateStatus()
	{
		var saveCount = 0;
		foreach (var summary in _saveManager.GetSlotSummaries())
		{
			if (summary.Exists)
			{
				saveCount++;
			}
		}

		_statusLabel.Text = saveCount > 0
			? TextDb.UiFormat("main_menu.status_has_save", saveCount)
			: TextDb.Ui("main_menu.status_no_save");
	}

	private void OnNewGamePressed()
	{
		SessionContext.PendingMenuMode = "new";
		GetTree().ChangeSceneToFile("res://Scenes/SaveSelect.tscn");
	}

	private void OnLoadGamePressed()
	{
		SessionContext.PendingMenuMode = "load";
		GetTree().ChangeSceneToFile("res://Scenes/SaveSelect.tscn");
	}

	private static string ResolveOriginalResourceRoot()
	{
		var projectRoot = ProjectSettings.GlobalizePath("res://").TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
		var originalRoot = Directory.GetParent(projectRoot)?.FullName
			?? throw new DirectoryNotFoundException("Cannot resolve original project root.");
		return Path.Combine(originalRoot, "resources");
	}
}
