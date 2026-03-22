using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Godot;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Data;
using EraKingdomRewrite.Scripts.Story;
using EraKingdomRewrite.Scripts.Text;
using EraKingdomRewrite.Scripts.Training;

namespace EraKingdomRewrite.Scripts.UI;

public partial class TrainingView : Control
{
    private const string KeyName = "名前";
    private const string KeyCallName = "呼び名";
    private const string KeyBase = "基礎";

    private const string Divider = "----------------------------";
    private const int CompactBarWidth = 18;
    private const int BaseGaugeMax = 10000;
    private const int PalamGaugeMax = 1200;
    private const int MoodGaugeMax = 100;
    private const int AbilityGaugeMax = 5;

    private Label _headerTitleLabel = null!;
    private Label _headerTextLabel = null!;
    private Label _playerStatusTitleLabel = null!;
    private RichTextLabel _playerStatusTextLabel = null!;
    private Label _targetStatusTitleLabel = null!;
    private RichTextLabel _targetStatusTextLabel = null!;
    private Label _commandTitleLabel = null!;
    private Label _commandHintLabel = null!;
    private GridContainer _commandGrid = null!;
    private Label _reactionTitleLabel = null!;
    private RichTextLabel _reactionTextLabel = null!;
    private Label _deltaTitleLabel = null!;
    private RichTextLabel _deltaTextLabel = null!;
    private Button _executeButton = null!;
    private Label _hintLabel = null!;
    private Button _endTrainingButton = null!;

    private SaveManager _saveManager = null!;
    private GameState _state = null!;
    private CharacterRepository _repository = null!;
    private MasterProfile _masterProfile = null!;
    private TrainingCommandDefinition? _selectedCommand;

    public override void _Ready()
    {
        UiThemeHelper.ApplyChineseTheme(this, 18);
        _headerTitleLabel = GetNode<Label>("Margin/Content/Header/HeaderBox/HeaderTitle");
        _headerTextLabel = GetNode<Label>("Margin/Content/Header/HeaderBox/HeaderText");
        _playerStatusTitleLabel = GetNode<Label>("Margin/Content/StatusRow/PlayerStatusPanel/PlayerStatusMargin/PlayerStatusBox/PlayerStatusTitle");
        _playerStatusTextLabel = GetNode<RichTextLabel>("Margin/Content/StatusRow/PlayerStatusPanel/PlayerStatusMargin/PlayerStatusBox/PlayerStatusText");
        _targetStatusTitleLabel = GetNode<Label>("Margin/Content/StatusRow/TargetStatusPanel/TargetStatusMargin/TargetStatusBox/TargetStatusTitle");
        _targetStatusTextLabel = GetNode<RichTextLabel>("Margin/Content/StatusRow/TargetStatusPanel/TargetStatusMargin/TargetStatusBox/TargetStatusText");
        _commandTitleLabel = GetNode<Label>("Margin/Content/Body/CommandPanel/CommandMargin/CommandBox/CommandTitle");
        _commandHintLabel = GetNode<Label>("Margin/Content/Body/CommandPanel/CommandMargin/CommandBox/CommandHint");
        _commandGrid = GetNode<GridContainer>("Margin/Content/Body/CommandPanel/CommandMargin/CommandBox/CommandScroll/CommandGrid");
        _reactionTitleLabel = GetNode<Label>("Margin/Content/Body/ReactionPanel/ReactionMargin/ReactionBox/ReactionTitle");
        _reactionTextLabel = GetNode<RichTextLabel>("Margin/Content/Body/ReactionPanel/ReactionMargin/ReactionBox/ReactionText");
        _deltaTitleLabel = GetNode<Label>("Margin/Content/Body/ReactionPanel/ReactionMargin/ReactionBox/DeltaTitle");
        _deltaTextLabel = GetNode<RichTextLabel>("Margin/Content/Body/ReactionPanel/ReactionMargin/ReactionBox/DeltaText");
        _executeButton = GetNode<Button>("Margin/Content/Body/ReactionPanel/ReactionMargin/ReactionBox/ActionRow/ExecuteButton");
        _hintLabel = GetNode<Label>("Margin/Content/Body/ReactionPanel/ReactionMargin/ReactionBox/ActionRow/HintLabel");
        _endTrainingButton = GetNode<Button>("Margin/Content/BottomBar/EndTrainingButton");

        _saveManager = new SaveManager();
        _state = SessionContext.ActiveState ?? new GameState();
        SessionContext.ActiveState = _state;
        _state.CurrentScene = "Training";

        _repository = new CharacterRepository();
        _repository.SeedDefaults(new CsvLoader().LoadDefaultRoster());
        _masterProfile = LoadMasterProfile();

        ApplyStaticTexts();
        BuildCommandButtons();
        RefreshScreen();
        SaveActiveState();
    }

    private void ApplyStaticTexts()
    {
        _headerTitleLabel.Text = TextDb.Ui("training.title");
        _playerStatusTitleLabel.Text = TextDb.Ui("training.player_status_title");
        _targetStatusTitleLabel.Text = TextDb.Ui("training.character_status_title");
        _commandTitleLabel.Text = TextDb.Ui("training.command_title");
        _commandHintLabel.Text = TextDb.Ui("training.command_hint_terminal");
        _reactionTitleLabel.Text = TextDb.Ui("training.reaction_title");
        _deltaTitleLabel.Text = TextDb.Ui("training.delta_title");
        _executeButton.Text = TextDb.Ui("training.execute");
        _endTrainingButton.Text = TextDb.Ui("training.end");
        _hintLabel.Text = TextDb.Ui("training.hint_default");
    }

    private void BuildCommandButtons()
    {
        foreach (var child in _commandGrid.GetChildren())
        {
            child.QueueFree();
        }

        foreach (var command in TrainingCommandCatalog.All)
        {
            var button = new Button
            {
                Text = TextDb.UiFormat("training.command_button_format", TextDb.Ui(command.NameKey), command.LegacyId),
                SizeFlagsHorizontal = SizeFlags.ExpandFill,
                Alignment = HorizontalAlignment.Center,
                ClipText = true,
                CustomMinimumSize = new Vector2(0, 36)
            };

            button.Pressed += () => SelectCommand(command.Id);
            _commandGrid.AddChild(button);
        }

        _selectedCommand = TrainingCommandCatalog.All.FirstOrDefault();
    }

    private void SelectCommand(string commandId)
    {
        _selectedCommand = TrainingCommandCatalog.GetRequired(commandId);
        RefreshScreen();
    }

    private void RefreshScreen()
    {
        var character = GetTargetCharacter();
        UpdateHeader();
        _playerStatusTextLabel.Text = BuildPlayerStatusText(character);
        _targetStatusTextLabel.Text = BuildTargetStatusText(character);
        RefreshReactionPanels();
    }

    private void UpdateHeader()
    {
        var period = _state.TimeSlot == 0 ? TextDb.Ui("common.daytime") : TextDb.Ui("common.nighttime");
        _headerTextLabel.Text = TextDb.UiFormat("training.header_line_format", _state.Day, period, _state.Money);
    }

    private string BuildPlayerStatusText(CharacterData? character)
    {
        var builder = new StringBuilder();
        builder.AppendLine(_masterProfile.Name);
        builder.AppendLine(Divider);
        var hp = GetBaseValue(_masterProfile.BaseStats, 0);
        var sp = GetBaseValue(_masterProfile.BaseStats, 1);
        var shoot = GetBaseValue(_masterProfile.BaseStats, 2);
        builder.AppendLine(BuildGaugeLine(TextDb.Ui("training.player_hp"), hp, hp));
        builder.AppendLine(BuildGaugeLine(TextDb.Ui("training.player_sp"), sp, sp));
        builder.AppendLine(BuildGaugeLine(TextDb.Ui("training.player_shoot"), shoot, BaseGaugeMax));

        if (character is not null)
        {
            var abilityValues = GetAbilityValues(character);
            builder.AppendLine();
            builder.AppendLine(Divider);
            builder.AppendLine(BuildLevelGaugePairLine("C", GetAbilityValue(abilityValues, 3), "V", GetAbilityValue(abilityValues, 4)));
            builder.AppendLine(BuildLevelGaugePairLine("A", GetAbilityValue(abilityValues, 5), "B", GetAbilityValue(abilityValues, 6)));
        }

        return builder.ToString().TrimEnd();
    }

    private string BuildTargetStatusText(CharacterData? character)
    {
        var builder = new StringBuilder();
        if (character is null)
        {
            return TextDb.Ui("training.target_empty");
        }

        var characterState = _state.GetOrCreateCharacter(character.No);
        builder.AppendLine(character.Name);
        builder.AppendLine(Divider);

        if (!characterState.IsOwned)
        {
            builder.Append(TextDb.Ui("training.hint_need_owned_target"));
            return builder.ToString().TrimEnd();
        }

        var targetBase = characterState.BaseStats.Count > 0 ? characterState.BaseStats : character.BaseStats;
        builder.AppendLine(BuildGaugeLine(TextDb.Ui("training.target_hp"), GetBaseValue(targetBase, 0), GetBaseValue(targetBase, 0)));
        builder.AppendLine(BuildGaugeLine(TextDb.Ui("training.target_sp"), GetBaseValue(targetBase, 1), GetBaseValue(targetBase, 1)));
        builder.AppendLine(BuildGaugeLine(TextDb.Ui("training.target_shoot"), GetBaseValue(targetBase, 2), BaseGaugeMax));
        builder.AppendLine();
        builder.AppendLine(BuildGaugePairLine(TextDb.Ui("training.palam_c"), characterState.GetPalam(0), TextDb.Ui("training.palam_lube"), characterState.GetPalam(4), PalamGaugeMax));
        builder.AppendLine(BuildGaugePairLine(TextDb.Ui("training.palam_v"), characterState.GetPalam(1), TextDb.Ui("training.palam_lust"), characterState.GetPalam(6), PalamGaugeMax));
        builder.AppendLine(BuildGaugePairLine(TextDb.Ui("training.palam_a"), characterState.GetPalam(2), TextDb.Ui("training.palam_shame"), characterState.GetPalam(9), PalamGaugeMax));
        builder.AppendLine(BuildGaugePairLine(TextDb.Ui("training.palam_b"), characterState.GetPalam(3), TextDb.Ui("training.palam_submission"), characterState.GetPalam(7), PalamGaugeMax));
        builder.AppendLine(BuildGaugePairLine(TextDb.Ui("training.palam_learning"), characterState.GetPalam(8), TextDb.Ui("training.palam_pain"), characterState.GetPalam(10), PalamGaugeMax));
        builder.AppendLine(BuildGaugePairLine(TextDb.Ui("training.palam_fear"), characterState.GetPalam(11), TextDb.Ui("training.palam_disgust"), characterState.GetPalam(12), PalamGaugeMax));
        builder.AppendLine(BuildGaugePairLine(TextDb.Ui("training.palam_depression"), characterState.GetPalam(14), TextDb.Ui("training.state_mood"), characterState.Mood, MoodGaugeMax));
        builder.Append(BuildGaugeLine(TextDb.Ui("training.state_stage"), (int)characterState.CurrentFallStage, (int)FallStage.Consort, GetFallStageText(characterState.CurrentFallStage)));
        return builder.ToString().TrimEnd();
    }

    private void RefreshReactionPanels()
    {
        var character = GetTargetCharacter();
        if (character is null)
        {
            ShowEmptyReaction(TextDb.Ui("training.hint_need_target"));
            return;
        }

        var characterState = _state.GetOrCreateCharacter(character.No);
        if (!characterState.IsOwned)
        {
            ShowEmptyReaction(TextDb.Ui("training.hint_need_owned_target"));
            return;
        }

        if (_selectedCommand is null)
        {
            ShowEmptyReaction(TextDb.Ui("training.preview_none"));
            return;
        }

        var calculator = new TrainingCalculator();
        var simulated = calculator.Simulate(character, characterState, _selectedCommand);
        var lines = new TrainingDialogueFactory().BuildLines(character, characterState, simulated);
        _reactionTextLabel.Text = string.Join(
            "\n\n",
            lines.Select(line => TextDb.UiFormat("training.reaction_line_format", line.Speaker, line.Text)));
        _deltaTextLabel.Text = BuildDeltaText(simulated);
        _hintLabel.Text = TextDb.UiFormat("training.hint_selected_format", TextDb.Ui(_selectedCommand.NameKey));
        _executeButton.Disabled = false;
    }

    private void ShowEmptyReaction(string hint)
    {
        _reactionTextLabel.Text = TextDb.Ui("training.preview_none");
        _deltaTextLabel.Text = TextDb.Ui("training.preview_none");
        _hintLabel.Text = hint;
        _executeButton.Disabled = true;
    }

    private static string BuildDeltaText(TrainingResult simulated)
    {
        var builder = new StringBuilder();
        builder.AppendLine(TextDb.UiFormat(
            "training.preview_runtime_format",
            FormatSigned(simulated.AppliedRelationDelta),
            FormatSigned(simulated.AppliedDependencyDelta),
            FormatSigned(simulated.AppliedStressDelta),
            FormatSigned(simulated.AppliedMoodDelta)));

        if (simulated.AppliedPalamDelta.Count > 0)
        {
            builder.AppendLine();
            foreach (var pair in simulated.AppliedPalamDelta.OrderBy(static pair => pair.Key))
            {
                builder.AppendLine(TextDb.UiFormat("training.result.stat_delta", CharacterStatCatalog.GetPalamName(pair.Key), FormatSigned(pair.Value)));
            }
        }

        if (simulated.AppliedExperienceDelta.Count > 0)
        {
            builder.AppendLine();
            foreach (var pair in simulated.AppliedExperienceDelta.OrderBy(static pair => pair.Key))
            {
                builder.AppendLine(TextDb.UiFormat("training.result.stat_delta", CharacterStatCatalog.GetExperienceName(pair.Key), FormatSigned(pair.Value)));
            }
        }

        return builder.ToString().Trim();
    }

    private CharacterData? GetTargetCharacter()
    {
        if (!_state.CurrentTargetCharacterId.HasValue)
        {
            return null;
        }

        return _repository.TryGet(_state.CurrentTargetCharacterId.Value, out var character) ? character : null;
    }

    private void OnExecutePressed()
    {
        var character = GetTargetCharacter();
        if (character is null || _selectedCommand is null)
        {
            RefreshScreen();
            return;
        }

        var characterState = _state.GetOrCreateCharacter(character.No);
        if (!characterState.IsOwned)
        {
            ShowEmptyReaction(TextDb.Ui("training.hint_need_owned_target"));
            return;
        }

        var result = new TrainingCalculator().Apply(_state, character, _selectedCommand);
        var commandName = TextDb.Ui(_selectedCommand.NameKey);
        _state.AddCharacterEvent(
            character.No,
            $"training.{_selectedCommand.Id}.{_state.EventLogSequence + 1}",
            TextDb.UiFormat("event_log.training_title", commandName),
            result.BuildSummaryText());

        SessionContext.PendingStoryRequest = new StoryPlaybackRequest
        {
            StoryId = $"training.{_selectedCommand.Id}",
            Title = TextDb.UiFormat("training.story_title_format", character.Name, commandName),
            Lines = new TrainingDialogueFactory().BuildLines(character, characterState, result).ToList(),
            ReturnScene = "res://Scenes/Training.tscn",
            ReturnSceneName = "Training",
            SkipText = TextDb.Ui("training.skip"),
            FinishText = TextDb.Ui("training.finish")
        };
        SaveActiveState();
        GetTree().ChangeSceneToFile("res://Scenes/StoryScene.tscn");
    }

    private void OnEndTrainingPressed()
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

    private static string BuildGaugePairLine(string leftLabel, int leftValue, string rightLabel, int rightValue, int max)
    {
        return $"{BuildGaugeLine(leftLabel, leftValue, max)}  {BuildGaugeLine(rightLabel, rightValue, max)}";
    }

    private static string BuildGaugeLine(string label, int current, int max, string? displayValue = null)
    {
        var safeMax = max <= 0 ? 1 : max;
        var clamped = Mathf.Clamp(current, 0, safeMax);
        var filledLength = Mathf.Clamp(Mathf.RoundToInt(clamped / (float)safeMax * CompactBarWidth), 0, CompactBarWidth);
        var bar = new string('■', filledLength) + new string('□', CompactBarWidth - filledLength);
        var valueText = displayValue ?? $"{current}/{safeMax}";
        return $"{label}[{bar}] {valueText}";
    }

    private IReadOnlyDictionary<int, int> GetAbilityValues(CharacterData character)
    {
        var state = _state.GetOrCreateCharacter(character.No);
        if (state.Abilities.Count > 0)
        {
            return state.Abilities;
        }

        return character.Abilities;
    }

    private static int GetAbilityValue(IReadOnlyDictionary<int, int> values, int id)
    {
        return values.TryGetValue(id, out var value) ? value : 0;
    }

    private static string BuildLevelGaugePairLine(string leftLabel, int leftValue, string rightLabel, int rightValue)
    {
        return $"{BuildGaugeLine(leftLabel, leftValue, AbilityGaugeMax, $"Lv{leftValue}")}  {BuildGaugeLine(rightLabel, rightValue, AbilityGaugeMax, $"Lv{rightValue}")}";
    }

    private static int GetBaseValue(IReadOnlyDictionary<int, int> values, int id)
    {
        return values.TryGetValue(id, out var value) ? value : 0;
    }

    private string GetFallStageText(FallStage stage)
    {
        return stage switch
        {
            FallStage.Love => TextDb.Ui("fall_stage.love"),
            FallStage.Obedience => TextDb.Ui("fall_stage.obedience"),
            FallStage.Lust => TextDb.Ui("fall_stage.lust"),
            FallStage.DeepLove => TextDb.Ui("fall_stage.deep_love"),
            FallStage.Slave => TextDb.Ui("fall_stage.slave"),
            FallStage.Consort => TextDb.Ui("fall_stage.consort"),
            _ => TextDb.Ui("fall_stage.none")
        };
    }

    private static string FormatSigned(int value)
    {
        return value >= 0 ? $"+{value}" : value.ToString();
    }

    private static MasterProfile LoadMasterProfile()
    {
        var profile = new MasterProfile
        {
            Name = TextDb.Ui("function_menu.master_name"),
            CallName = TextDb.Ui("function_menu.master_name")
        };

        try
        {
            var projectRoot = ProjectSettings.GlobalizePath("res://").TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
            var originalRoot = Directory.GetParent(projectRoot)?.FullName
                ?? throw new DirectoryNotFoundException("Cannot resolve original project root.");
            var path = Path.Combine(originalRoot, "CSV", "Chara", "Chara0_主人公.csv");
            if (!File.Exists(path))
            {
                return profile;
            }

            foreach (var rawLine in File.ReadLines(path, Encoding.UTF8))
            {
                if (string.IsNullOrWhiteSpace(rawLine) || rawLine.StartsWith(';'))
                {
                    continue;
                }

                var row = rawLine.Split(',');
                if (row.Length == 0)
                {
                    continue;
                }

                switch (row[0].Trim())
                {
                    case KeyName:
                        if (row.Length > 1 && !string.IsNullOrWhiteSpace(row[1]))
                        {
                            profile.Name = row[1].Trim();
                        }
                        break;
                    case KeyCallName:
                        if (row.Length > 1 && !string.IsNullOrWhiteSpace(row[1]))
                        {
                            profile.CallName = row[1].Trim();
                        }
                        break;
                    case KeyBase:
                        if (row.Length > 2 && int.TryParse(row[1], out var baseId) && int.TryParse(row[2], out var baseValue))
                        {
                            profile.BaseStats[baseId] = baseValue;
                        }
                        break;
                }
            }
        }
        catch
        {
            return profile;
        }

        return profile;
    }

    private sealed class MasterProfile
    {
        public string Name { get; set; } = string.Empty;
        public string CallName { get; set; } = string.Empty;
        public Dictionary<int, int> BaseStats { get; } = new();
    }
}
