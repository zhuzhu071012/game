using System.Collections.Generic;
using System.IO;
using System.Linq;
using Godot;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Data;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.UI;

public partial class ShopView : Control
{
	private VBoxContainer _characterList = null!;
	private Label _headerTitleLabel = null!;
	private Label _headerLabel = null!;
	private Label _rosterTitleLabel = null!;
	private Label _rosterHintLabel = null!;
	private Label _manualTitleLabel = null!;
	private Label _metaLabel = null!;
	private RichTextLabel _summaryLabel = null!;
	private TextureRect _portraitRect = null!;
	private Button _actionButton = null!;
	private Label _hintLabel = null!;
	private Button _backButton = null!;

	private GameState _state = null!;
	private SaveManager _saveManager = null!;
	private CharacterRepository _repository = null!;
	private int _selectedCharacterId;

	public override void _Ready()
	{
		UiThemeHelper.ApplyChineseTheme(this);
		_characterList = GetNode<VBoxContainer>("Margin/Content/Body/RosterPanel/RosterMargin/RosterBox/RosterScroll/CharacterList");
		_headerTitleLabel = GetNode<Label>("Margin/Content/Header/HeaderBox/HeaderTitle");
		_headerLabel = GetNode<Label>("Margin/Content/Header/HeaderBox/HeaderText");
		_rosterTitleLabel = GetNode<Label>("Margin/Content/Body/RosterPanel/RosterMargin/RosterBox/RosterTitle");
		_rosterHintLabel = GetNode<Label>("Margin/Content/Body/RosterPanel/RosterMargin/RosterBox/RosterHint");
		_manualTitleLabel = GetNode<Label>("Margin/Content/Body/DetailPanel/DetailMargin/DetailBox/TopRow/InfoBox/ManualTitle");
		_metaLabel = GetNode<Label>("Margin/Content/Body/DetailPanel/DetailMargin/DetailBox/TopRow/InfoBox/Meta");
		_summaryLabel = GetNode<RichTextLabel>("Margin/Content/Body/DetailPanel/DetailMargin/DetailBox/TopRow/InfoBox/Summary");
		_portraitRect = GetNode<TextureRect>("Margin/Content/Body/DetailPanel/DetailMargin/DetailBox/TopRow/PortraitFrame/PortraitMargin/Portrait");
		_actionButton = GetNode<Button>("Margin/Content/Body/DetailPanel/DetailMargin/DetailBox/ActionRow/ActionButton");
		_hintLabel = GetNode<Label>("Margin/Content/Body/DetailPanel/DetailMargin/DetailBox/ActionRow/HintLabel");
		_backButton = GetNode<Button>("Margin/Content/BottomBar/Back");

		_saveManager = new SaveManager();
		_state = SessionContext.ActiveState ?? new GameState();
		SessionContext.ActiveState = _state;

		var loader = new CsvLoader();
		_repository = new CharacterRepository();
		_repository.SeedDefaults(loader.LoadDefaultRoster());

		ApplyStaticTexts();
		UpdateHeader();
		BuildCharacterButtons();
		ShowDefaultCharacter();
	}

	private void ApplyStaticTexts()
	{
		_headerTitleLabel.Text = TextDb.Ui("shop.header_title");
		_rosterTitleLabel.Text = TextDb.Ui("shop.roster_title");
		_rosterHintLabel.Text = TextDb.Ui("shop.roster_hint");
		_actionButton.Text = TextDb.Ui("shop.select");
		_backButton.Text = TextDb.Ui("shop.back");
	}

	private void UpdateHeader()
	{
		var period = _state.TimeSlot == 0 ? TextDb.Ui("common.daytime") : TextDb.Ui("common.nighttime");
		_headerLabel.Text = TextDb.UiFormat("shop.header_text_format", _state.Day, period, _state.Money);
	}

	private void BuildCharacterButtons()
	{
		foreach (var child in _characterList.GetChildren())
		{
			child.QueueFree();
		}

		foreach (var character in _repository.All.OrderBy(character => character.No))
		{
			var unlocked = _state.IsPoolUnlocked(character.PoolId);
			var button = new Button
			{
				Text = character.Name,
				SizeFlagsHorizontal = SizeFlags.ExpandFill,
				Alignment = HorizontalAlignment.Left,
				ClipText = true,
				CustomMinimumSize = new Vector2(0, 42)
			};

			if (!unlocked)
			{
				button.Text += TextDb.Ui("shop.locked_suffix");
			}

			button.Pressed += () => ShowCharacterDetail(character.No);
			_characterList.AddChild(button);
		}
	}

	private void ShowDefaultCharacter()
	{
		var selectedId = _state.CurrentTargetCharacterId ?? _repository.All.OrderBy(character => character.No).Select(character => (int?)character.No).FirstOrDefault();
		if (!selectedId.HasValue)
		{
			_manualTitleLabel.Text = TextDb.Ui("shop.no_character");
			_metaLabel.Text = string.Empty;
			_summaryLabel.Text = string.Empty;
			_actionButton.Disabled = true;
			return;
		}

		ShowCharacterDetail(selectedId.Value);
	}

	private void ShowCharacterDetail(int characterId)
	{
		_selectedCharacterId = characterId;
		_state.CurrentTargetCharacterId = characterId;

		var character = _repository.GetRequired(characterId);
		var unlocked = _state.IsPoolUnlocked(character.PoolId);
		_manualTitleLabel.Text = character.Name;
		_metaLabel.Text = BuildMetaText(character);
		_summaryLabel.Text = BuildSummaryText(character);
		_portraitRect.Texture = LoadPortrait(character.PortraitId);

		_actionButton.Disabled = !unlocked;
		_actionButton.Text = unlocked ? TextDb.Ui("shop.select") : TextDb.Ui("shop.locked");
		_hintLabel.Text = unlocked
			? string.Empty
			: TextDb.Ui("shop.hint_locked");

		SaveActiveState();
	}

	private static string BuildMetaText(CharacterData character)
	{
		var faction = string.IsNullOrWhiteSpace(character.Faction) ? TextDb.Ui("shop.faction_unknown") : character.Faction;
		return TextDb.UiFormat("shop.meta_format", character.Difficulty, character.Persona, faction, character.Job);
	}

	private static string BuildSummaryText(CharacterData character)
	{
		var profileLines = Enumerable.Range(92, 7)
			.Select(character.GetProfileLine)
			.Where(static line => !string.IsNullOrWhiteSpace(line))
			.ToList();

		return profileLines.Count == 0
			? TextDb.Ui("shop.no_profile")
			: "\n" + string.Join("\n", profileLines);
	}

	private Texture2D? LoadPortrait(int portraitId)
	{
		if (portraitId <= 0)
		{
			return null;
		}

		foreach (var portraitPath in EnumeratePortraitCandidates(portraitId))
		{
			if (!File.Exists(portraitPath))
			{
				continue;
			}

			var image = new Image();
			var error = image.Load(portraitPath);
			if (error == Error.Ok)
			{
				return ImageTexture.CreateFromImage(image);
			}

			GD.PushWarning($"Failed to load portrait: {portraitPath} ({error})");
		}

		GD.PushWarning($"Portrait file not found for id {portraitId}.");
		return null;
	}

	private static IEnumerable<string> EnumeratePortraitCandidates(int portraitId)
	{
		var fileName = $"600_{portraitId}.png";
		yield return Path.Combine(ResolveOriginalResourceRoot(), fileName);
		yield return Path.Combine(ProjectSettings.GlobalizePath("res://"), "Resources", "portraits", fileName);
	}

	private static string ResolveOriginalResourceRoot()
	{
		var projectRoot = ProjectSettings.GlobalizePath("res://").TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
		var originalRoot = Directory.GetParent(projectRoot)?.FullName
			?? throw new DirectoryNotFoundException("Cannot resolve original project root.");
		return Path.Combine(originalRoot, "resources");
	}

	private void OnActionButtonPressed()
	{
		if (_selectedCharacterId == 0)
		{
			return;
		}

		_state.CurrentTargetCharacterId = _selectedCharacterId;
		var characterState = _state.GetOrCreateCharacter(_selectedCharacterId);
		characterState.HasMet = true;
		SaveActiveState();

		var character = _repository.GetRequired(_selectedCharacterId);
		_hintLabel.Text = TextDb.UiFormat("shop.hint_selected", character.Name);
	}

	private void OnBackPressed()
	{
		SaveActiveState();
		GetTree().ChangeSceneToFile("res://Scenes/FunctionMenu.tscn");
	}

	private void SaveActiveState()
	{
		if (SessionContext.ActiveSlot > 0)
		{
			_saveManager.Save(_state, SessionContext.ActiveSlot);
		}
	}
}
