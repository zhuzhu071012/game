using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Godot;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Data;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.UI;

public partial class CharacterStatusView : Control
{
    private const int MasterSelectionId = -1;
    private static readonly Color ActiveTabColor = new(0.976f, 0.906f, 0.792f, 1f);
    private static readonly Color InactiveTabColor = new(0.86f, 0.9f, 0.97f, 0.96f);
    private static readonly Color CurrentRosterColor = new(0.964f, 0.898f, 0.772f, 1f);
    private static readonly Color AvailableRosterColor = new(0.88f, 0.92f, 0.98f, 0.94f);
    private static readonly Color LockedRosterColor = new(0.67f, 0.71f, 0.8f, 0.82f);

    private enum StatusTab
    {
        Growth,
        Relation,
        Events
    }

    private const string KeyName = "名前";
    private const string KeyCallName = "呼び名";
    private const string KeyBase = "基礎";
    private const string KeyAbility = "能力";

    private Label _headerTitleLabel = null!;
    private Label _headerTextLabel = null!;
    private Label _rosterTitleLabel = null!;
    private Label _rosterHintLabel = null!;
    private VBoxContainer _characterList = null!;
    private PanelContainer _masterPanel = null!;
    private Label _masterTitleLabel = null!;
    private RichTextLabel _masterTextLabel = null!;
    private PanelContainer _characterPanel = null!;
    private TextureRect _portraitRect = null!;
    private Label _nameLabel = null!;
    private Label _metaLabel = null!;
    private Label _summaryTitleLabel = null!;
    private RichTextLabel _summaryTextLabel = null!;
    private Button _growthTabButton = null!;
    private Button _relationTabButton = null!;
    private Button _eventTabButton = null!;
    private Label _tabTitleLabel = null!;
    private RichTextLabel _tabTextLabel = null!;
    private Label _hintLabel = null!;
    private Button _backButton = null!;

    private SaveManager _saveManager = null!;
    private GameState _state = null!;
    private CharacterRepository _repository = null!;
    private MasterProfile _masterProfile = null!;
    private int _selectedCharacterId;
    private StatusTab _activeTab = StatusTab.Growth;

    public override void _Ready()
    {
        UiThemeHelper.ApplyChineseTheme(this);
        _headerTitleLabel = GetNode<Label>("Margin/Content/Header/HeaderBox/HeaderTitle");
        _headerTextLabel = GetNode<Label>("Margin/Content/Header/HeaderBox/HeaderText");
        _rosterTitleLabel = GetNode<Label>("Margin/Content/Body/RosterPanel/RosterMargin/RosterBox/RosterTitle");
        _rosterHintLabel = GetNode<Label>("Margin/Content/Body/RosterPanel/RosterMargin/RosterBox/RosterHint");
        _characterList = GetNode<VBoxContainer>("Margin/Content/Body/RosterPanel/RosterMargin/RosterBox/RosterScroll/CharacterList");
        _masterPanel = GetNode<PanelContainer>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/MasterPanel");
        _masterTitleLabel = GetNode<Label>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/MasterPanel/MasterMargin/MasterBox/MasterTitle");
        _masterTextLabel = GetNode<RichTextLabel>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/MasterPanel/MasterMargin/MasterBox/MasterText");
        _characterPanel = GetNode<PanelContainer>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/CharacterPanel");
        _portraitRect = GetNode<TextureRect>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/CharacterPanel/CharacterMargin/TopRow/PortraitFrame/PortraitMargin/Portrait");
        _nameLabel = GetNode<Label>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/CharacterPanel/CharacterMargin/TopRow/Overview/Name");
        _metaLabel = GetNode<Label>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/CharacterPanel/CharacterMargin/TopRow/Overview/Meta");
        _summaryTitleLabel = GetNode<Label>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/CharacterPanel/CharacterMargin/TopRow/Overview/SummaryTitle");
        _summaryTextLabel = GetNode<RichTextLabel>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/CharacterPanel/CharacterMargin/TopRow/Overview/SummaryText");
        _growthTabButton = GetNode<Button>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/TabBar/GrowthTabButton");
        _relationTabButton = GetNode<Button>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/TabBar/RelationTabButton");
        _eventTabButton = GetNode<Button>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/TabBar/EventTabButton");
        _tabTitleLabel = GetNode<Label>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/TabTitle");
        _tabTextLabel = GetNode<RichTextLabel>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/TabText");
        _hintLabel = GetNode<Label>("Margin/Content/Body/DetailPanel/DetailMargin/DetailScroll/DetailBox/HintLabel");
        _backButton = GetNode<Button>("Margin/Content/BottomBar/Back");

        _saveManager = new SaveManager();
        _state = SessionContext.ActiveState ?? new GameState();
        SessionContext.ActiveState = _state;
        _state.CurrentScene = "Status";

        _repository = new CharacterRepository();
        _repository.SeedDefaults(new CsvLoader().LoadDefaultRoster());
        _masterProfile = LoadMasterProfile();

        ApplyStaticTexts();
        BuildCharacterButtons();
        ShowDefaultCharacter();
        SaveActiveState();
    }

    private void ApplyStaticTexts()
    {
        _headerTitleLabel.Text = TextDb.Ui("status_scene.title");
        _rosterTitleLabel.Text = TextDb.Ui("status_scene.roster_title");
        _rosterHintLabel.Text = TextDb.Ui("status_scene.roster_hint");
        _masterTitleLabel.Text = TextDb.Ui("status_scene.master_title");
        _summaryTitleLabel.Text = TextDb.Ui("status_scene.summary_title");
        _growthTabButton.Text = TextDb.Ui("status_scene.tab_growth");
        _relationTabButton.Text = TextDb.Ui("status_scene.tab_relation");
        _eventTabButton.Text = TextDb.Ui("status_scene.tab_events");
        _backButton.Text = TextDb.Ui("status_scene.back");
        _hintLabel.Text = TextDb.Ui("status_scene.hint_default");
        UpdateTabButtons();
    }

    private void BuildCharacterButtons()
    {
        foreach (var child in _characterList.GetChildren())
        {
            child.QueueFree();
        }

        AddRosterButton(
            TextDb.Ui("status_scene.master_roster"),
            MasterSelectionId,
            _selectedCharacterId == MasterSelectionId,
            true);

        foreach (var character in _repository.All.OrderBy(character => character.No))
        {
            var unlocked = _state.IsPoolUnlocked(character.PoolId);
            AddRosterButton(character.Name, character.No, _selectedCharacterId == character.No, unlocked);
        }
    }

    private void AddRosterButton(string label, int selectionId, bool isCurrent, bool unlocked)
    {
        var button = new Button
        {
            Text = BuildRosterText(label, isCurrent, unlocked),
            SizeFlagsHorizontal = SizeFlags.ExpandFill,
            Alignment = HorizontalAlignment.Left,
            ClipText = true,
            CustomMinimumSize = new Vector2(0, 42)
        };
        button.Modulate = isCurrent
            ? CurrentRosterColor
            : unlocked
                ? AvailableRosterColor
                : LockedRosterColor;

        button.Pressed += () =>
        {
            if (selectionId == MasterSelectionId)
            {
                ShowMasterDetail();
                return;
            }

            ShowCharacterDetail(selectionId);
        };
        _characterList.AddChild(button);
    }

    private string BuildRosterText(string name, bool isCurrent, bool unlocked)
    {
        var text = isCurrent ? TextDb.UiFormat("status_scene.roster_current_format", name) : name;
        if (!unlocked)
        {
            text += TextDb.Ui("shop.locked_suffix");
        }

        return text;
    }

    private void ShowDefaultCharacter()
    {
        if (_state.CurrentTargetCharacterId.HasValue
            && _repository.TryGet(_state.CurrentTargetCharacterId.Value, out var character)
            && character is not null)
        {
            ShowCharacterDetail(_state.CurrentTargetCharacterId.Value);
            return;
        }

        ShowMasterDetail();
    }

    private void ShowCharacterDetail(int characterId)
    {
        _selectedCharacterId = characterId;
        _state.CurrentTargetCharacterId = characterId;

        var character = _repository.GetRequired(characterId);
        var characterState = _state.GetOrCreateCharacter(characterId);

        _headerTextLabel.Text = BuildHeaderText(character.Name);
        _nameLabel.Text = character.Name;
        _metaLabel.Text = BuildMetaText(character);
        _summaryTextLabel.Text = BuildSummaryText(character, characterState);
        _portraitRect.Texture = CharacterPortraitLoader.LoadPortrait(character.PortraitId);
        _hintLabel.Text = TextDb.UiFormat("status_scene.hint_selected", character.Name);

        _masterPanel.Visible = false;
        _characterPanel.Visible = true;
        RefreshTabContent(character, characterState);
        BuildCharacterButtons();
        SaveActiveState();
    }

    private void ShowMasterDetail()
    {
        _selectedCharacterId = MasterSelectionId;
        _headerTextLabel.Text = BuildHeaderText(_masterProfile.Name);
        _hintLabel.Text = TextDb.Ui("status_scene.hint_master");

        RefreshMasterPanel();
        _masterPanel.Visible = true;
        _characterPanel.Visible = false;
        RefreshMasterTabContent();
        BuildCharacterButtons();
        SaveActiveState();
    }

    private void ClearDetail()
    {
        _headerTextLabel.Text = BuildHeaderText(TextDb.Ui("status_scene.no_character"));
        _nameLabel.Text = TextDb.Ui("status_scene.no_character");
        _metaLabel.Text = string.Empty;
        _summaryTextLabel.Text = TextDb.Ui("status_scene.none_data");
        _tabTitleLabel.Text = TextDb.Ui("status_scene.none_data");
        _tabTextLabel.Text = TextDb.Ui("status_scene.none_data");
        _portraitRect.Texture = null;
        _hintLabel.Text = TextDb.Ui("status_scene.hint_default");
        _masterPanel.Visible = false;
        _characterPanel.Visible = false;
    }

    private string BuildHeaderText(string currentName)
    {
        var period = _state.TimeSlot == 0 ? TextDb.Ui("common.daytime") : TextDb.Ui("common.nighttime");
        return TextDb.UiFormat("status_scene.header_text_format", _state.Day, period, _state.Money, currentName);
    }

    private void RefreshMasterPanel()
    {
        var period = _state.TimeSlot == 0 ? TextDb.Ui("common.daytime") : TextDb.Ui("common.nighttime");
        var activeSlot = SessionContext.ActiveSlot > 0 ? SessionContext.ActiveSlot.ToString() : "-";
        var currentTarget = GetCurrentTargetDisplayName();
        var unlockedPools = _state.UnlockedPools.Count == 0
            ? "-"
            : string.Join(" / ", _state.UnlockedPools.OrderBy(static pool => pool).Select(GetPoolDisplayText));
        var baseText = BuildInlineStatText(_masterProfile.BaseStats, CharacterStatCatalog.GetBaseName);
        var abilityText = BuildInlineStatText(_masterProfile.Abilities, CharacterStatCatalog.GetAbilityName);

        _masterTextLabel.Text = TextDb.UiFormat(
            "status_scene.master_format",
            _masterProfile.Name,
            _masterProfile.CallName,
            _state.Day,
            period,
            _state.CurrentScene,
            activeSlot,
            _state.Money,
            unlockedPools,
            currentTarget,
            baseText,
            abilityText);
    }

    private string GetCurrentTargetDisplayName()
    {
        if (!_state.CurrentTargetCharacterId.HasValue)
        {
            return TextDb.Ui("status_scene.master_no_target");
        }

        if (_repository.TryGet(_state.CurrentTargetCharacterId.Value, out var character) && character is not null)
        {
            return character.Name;
        }

        return TextDb.UiFormat("status_scene.master_unknown_target", _state.CurrentTargetCharacterId.Value);
    }

    private static string BuildMetaText(CharacterData character)
    {
        var faction = string.IsNullOrWhiteSpace(character.Faction) ? TextDb.Ui("shop.faction_unknown") : character.Faction;
        var job = string.IsNullOrWhiteSpace(character.Job) ? "-" : character.Job;
        var difficulty = string.IsNullOrWhiteSpace(character.Difficulty) ? "-" : character.Difficulty;
        var persona = string.IsNullOrWhiteSpace(character.Persona) ? "-" : character.Persona;
        var callName = string.IsNullOrWhiteSpace(character.CallName) ? character.Name : character.CallName;
        return TextDb.UiFormat("status_scene.meta_format", faction, job, difficulty, persona, callName);
    }

    private string BuildSummaryText(CharacterData character, CharacterState characterState)
    {
        var profilePreview = Enumerable.Range(92, 2)
            .Select(character.GetProfileLine)
            .Where(static line => !string.IsNullOrWhiteSpace(line))
            .ToList();

        var reachedStages = characterState.ReachedFallStages.Count == 0
            ? TextDb.Ui("status_scene.none_reached")
            : string.Join(" / ", characterState.ReachedFallStages.OrderBy(static stage => stage).Select(GetFallStageText));
        var previewText = profilePreview.Count == 0 ? TextDb.Ui("shop.no_profile") : string.Join("\n", profilePreview);
        return TextDb.UiFormat(
            "status_scene.overview_format",
            TextDb.UiFormat(
                "status_scene.state_format",
                characterState.RelationToPlayer,
                characterState.Dependency,
                characterState.Stress,
                characterState.Mood,
                GetFallStageText(characterState.CurrentFallStage)),
            reachedStages,
            previewText);
    }

    private void RefreshTabContent(CharacterData character, CharacterState characterState)
    {
        switch (_activeTab)
        {
            case StatusTab.Relation:
                _tabTitleLabel.Text = TextDb.Ui("status_scene.tab_relation_title");
                _tabTextLabel.Text = BuildRelationTabText(character, characterState);
                break;
            case StatusTab.Events:
                _tabTitleLabel.Text = TextDb.Ui("status_scene.tab_events_title");
                _tabTextLabel.Text = BuildEventsTabText(character, characterState);
                break;
            default:
                _tabTitleLabel.Text = TextDb.Ui("status_scene.tab_growth_title");
                _tabTextLabel.Text = BuildGrowthTabText(character, characterState);
                break;
        }

        UpdateTabButtons();
    }

    private void RefreshMasterTabContent()
    {
        switch (_activeTab)
        {
            case StatusTab.Relation:
                _tabTitleLabel.Text = TextDb.Ui("status_scene.tab_relation_title");
                _tabTextLabel.Text = BuildMasterRelationTabText();
                break;
            case StatusTab.Events:
                _tabTitleLabel.Text = TextDb.Ui("status_scene.tab_events_title");
                _tabTextLabel.Text = BuildMasterEventsTabText();
                break;
            default:
                _tabTitleLabel.Text = TextDb.Ui("status_scene.tab_growth_title");
                _tabTextLabel.Text = BuildMasterGrowthTabText();
                break;
        }

        UpdateTabButtons();
    }

    private string BuildMasterGrowthTabText()
    {
        var builder = new StringBuilder();
        AppendSection(builder, TextDb.Ui("status_scene.section_base"), BuildIndexedText(_masterProfile.BaseStats, CharacterStatCatalog.GetBaseName));
        AppendSection(builder, TextDb.Ui("status_scene.section_ability"), BuildIndexedText(_masterProfile.Abilities, CharacterStatCatalog.GetAbilityName));
        return builder.ToString();
    }

    private string BuildMasterRelationTabText()
    {
        var builder = new StringBuilder();
        var period = _state.TimeSlot == 0 ? TextDb.Ui("common.daytime") : TextDb.Ui("common.nighttime");
        var activeSlot = SessionContext.ActiveSlot > 0 ? SessionContext.ActiveSlot.ToString() : "-";
        var unlockedPools = _state.UnlockedPools.Count == 0
            ? "-"
            : string.Join(" / ", _state.UnlockedPools.OrderBy(static pool => pool).Select(GetPoolDisplayText));

        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_runtime"),
            TextDb.UiFormat(
                "status_scene.master_state_format",
                _state.Day,
                period,
                _state.Money,
                _state.CurrentScene,
                activeSlot));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_flags"),
            TextDb.UiFormat(
                "status_scene.master_flags_format",
                GetCurrentTargetDisplayName(),
                unlockedPools,
                _state.TriggeredStoryIds.Count,
                _state.CompletedStoryIds.Count));
        return builder.ToString();
    }

    private string BuildMasterEventsTabText()
    {
        var builder = new StringBuilder();
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_event_records"),
            BuildEventLogText(_state.EventLog, TextDb.Ui("status_scene.no_events")));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_story_progress"),
            TextDb.UiFormat(
                "status_scene.story_progress_format",
                BuildStringListText(_state.TriggeredStoryIds, TextDb.Ui("status_scene.no_story_progress")),
                BuildStringListText(_state.CompletedStoryIds, TextDb.Ui("status_scene.no_story_progress"))));
        return builder.ToString();
    }

    private string BuildGrowthTabText(CharacterData character, CharacterState characterState)
    {
        var builder = new StringBuilder();
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_base"),
            BuildIndexedText(characterState.BaseStats.Count > 0 ? characterState.BaseStats : character.BaseStats, CharacterStatCatalog.GetBaseName));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_ability"),
            BuildIndexedText(characterState.Abilities.Count > 0 ? characterState.Abilities : character.Abilities, CharacterStatCatalog.GetAbilityName));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_experience"),
            BuildIndexedText(characterState.Experience, CharacterStatCatalog.GetExperienceName));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_traits"),
            BuildTraitsText(character, characterState));
        return builder.ToString();
    }

    private string BuildRelationTabText(CharacterData character, CharacterState characterState)
    {
        var builder = new StringBuilder();
        var unlocked = _state.IsPoolUnlocked(character.PoolId);
        var reachedStages = characterState.ReachedFallStages.Count == 0
            ? TextDb.Ui("status_scene.none_reached")
            : string.Join(" / ", characterState.ReachedFallStages.OrderBy(static stage => stage).Select(GetFallStageText));

        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_runtime"),
            TextDb.UiFormat(
                "status_scene.state_format",
                characterState.RelationToPlayer,
                characterState.Dependency,
                characterState.Stress,
                characterState.Mood,
                GetFallStageText(characterState.CurrentFallStage))
            + "\n"
            + TextDb.UiFormat("status_scene.reached_stage_format", reachedStages));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_marks"),
            BuildIndexedText(characterState.Marks, CharacterStatCatalog.GetMarkName));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_palam"),
            BuildIndexedText(characterState.Palam, CharacterStatCatalog.GetPalamName));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_flags"),
            TextDb.UiFormat(
                "status_scene.flags_format",
                BoolText(characterState.HasMet),
                BoolText(characterState.IsOwned),
                BoolText(characterState.IsUnlocked),
                BoolText(unlocked),
                reachedStages,
                characterState.TriggeredStoryIds.Count)
            + "\n"
            + TextDb.UiFormat("status_scene.pool_format", GetPoolDisplayText(character.PoolId)));
        return builder.ToString();
    }

    private string BuildEventsTabText(CharacterData character, CharacterState characterState)
    {
        var builder = new StringBuilder();
        AppendSection(builder, TextDb.Ui("status_scene.section_profile"), BuildProfileText(character));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_event_records"),
            BuildEventLogText(characterState.EventLog, TextDb.Ui("status_scene.no_events")));
        AppendSection(
            builder,
            TextDb.Ui("status_scene.section_story_progress"),
            TextDb.UiFormat(
                "status_scene.story_progress_format",
                BuildStringListText(_state.TriggeredStoryIds, TextDb.Ui("status_scene.no_story_progress")),
                BuildStringListText(_state.CompletedStoryIds, TextDb.Ui("status_scene.no_story_progress"))));
        return builder.ToString();
    }

    private void AppendSection(StringBuilder builder, string title, string body)
    {
        if (builder.Length > 0)
        {
            builder.Append("\n\n");
        }

        builder.Append("【");
        builder.Append(title);
        builder.Append("】\n");
        builder.Append(string.IsNullOrWhiteSpace(body) ? TextDb.Ui("status_scene.none_data") : body);
    }

    private static string BuildProfileText(CharacterData character)
    {
        var profileLines = Enumerable.Range(92, 7)
            .Select(character.GetProfileLine)
            .Where(static line => !string.IsNullOrWhiteSpace(line))
            .ToList();

        return profileLines.Count == 0 ? TextDb.Ui("shop.no_profile") : string.Join("\n", profileLines);
    }

    private string BuildTraitsText(CharacterData character, CharacterState characterState)
    {
        var activeTraits = characterState.ActiveTraits.OrderBy(static trait => trait).ToList();
        var innateTraits = character.Talents.OrderBy(static trait => trait).ToList();

        if (activeTraits.Count == 0 && innateTraits.Count == 0)
        {
            return TextDb.Ui("status_scene.none_data");
        }

        var builder = new StringBuilder();
        if (activeTraits.Count > 0)
        {
            builder.Append(TextDb.UiFormat("status_scene.active_traits_format", string.Join("、", activeTraits)));
        }

        if (innateTraits.Count > 0)
        {
            if (builder.Length > 0)
            {
                builder.Append("\n\n");
            }

            builder.Append(string.Join("、", innateTraits));
        }

        return builder.ToString();
    }

    private string BuildIndexedText(IReadOnlyDictionary<int, int> values, System.Func<int, string> nameResolver)
    {
        if (values.Count == 0)
        {
            return TextDb.Ui("status_scene.none_data");
        }

        return string.Join(
            "\n",
            values.OrderBy(static pair => pair.Key)
                .Select(pair => TextDb.UiFormat("status_scene.value_line_format", nameResolver(pair.Key), pair.Value)));
    }

    private string BuildInlineStatText(IReadOnlyDictionary<int, int> values, System.Func<int, string> nameResolver)
    {
        if (values.Count == 0)
        {
            return TextDb.Ui("status_scene.none_data");
        }

        return string.Join(
            " / ",
            values.OrderBy(static pair => pair.Key)
                .Select(pair => $"{nameResolver(pair.Key)} {pair.Value}"));
    }

    private string BuildStringListText(IEnumerable<string> values, string emptyText)
    {
        var items = values.Where(static value => !string.IsNullOrWhiteSpace(value)).OrderBy(static value => value).ToList();
        return items.Count == 0 ? emptyText : string.Join("\n", items);
    }

    private string BuildEventLogText(IEnumerable<EventLogEntry> events, string emptyText)
    {
        var items = events
            .OrderByDescending(static entry => entry.Sequence)
            .ThenByDescending(static entry => entry.Day)
            .Select(BuildEventLogEntryText)
            .Where(static entry => !string.IsNullOrWhiteSpace(entry))
            .ToList();

        return items.Count == 0 ? emptyText : string.Join("\n\n", items);
    }

    private string BuildEventLogEntryText(EventLogEntry entry)
    {
        var period = entry.TimeSlot == 0 ? TextDb.Ui("common.daytime") : TextDb.Ui("common.nighttime");
        var scene = GetSceneDisplayText(entry.Scene);
        if (string.IsNullOrWhiteSpace(entry.Detail))
        {
            return TextDb.UiFormat("status_scene.event_log_brief_format", entry.Day, period, scene, entry.Title);
        }

        return TextDb.UiFormat("status_scene.event_log_format", entry.Day, period, scene, entry.Title, entry.Detail);
    }

    private string GetSceneDisplayText(string scene)
    {
        return scene switch
        {
            "StoryScene" => TextDb.Ui("scene.story_scene"),
            "FunctionMenu" => TextDb.Ui("scene.function_menu"),
            "Shop" => TextDb.Ui("scene.shop"),
            "Training" => TextDb.Ui("scene.training"),
            "Status" => TextDb.Ui("scene.status"),
            _ => string.IsNullOrWhiteSpace(scene) ? "-" : scene
        };
    }

    private void UpdateTabButtons()
    {
        _growthTabButton.Disabled = _activeTab == StatusTab.Growth;
        _relationTabButton.Disabled = _activeTab == StatusTab.Relation;
        _eventTabButton.Disabled = _activeTab == StatusTab.Events;
        _growthTabButton.Modulate = _activeTab == StatusTab.Growth ? ActiveTabColor : InactiveTabColor;
        _relationTabButton.Modulate = _activeTab == StatusTab.Relation ? ActiveTabColor : InactiveTabColor;
        _eventTabButton.Modulate = _activeTab == StatusTab.Events ? ActiveTabColor : InactiveTabColor;
    }

    private static string GetPoolDisplayText(string? poolId)
    {
        if (string.IsNullOrWhiteSpace(poolId))
        {
            return "-";
        }

        var key = $"pool.{poolId.Trim().ToLowerInvariant()}";
        var translated = TextDb.Ui(key);
        return translated == key ? poolId : translated;
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

    private string BoolText(bool value)
    {
        return TextDb.Ui(value ? "common.yes" : "common.no");
    }

    private void OnGrowthTabPressed()
    {
        _activeTab = StatusTab.Growth;
        RefreshSelectedTab();
    }

    private void OnRelationTabPressed()
    {
        _activeTab = StatusTab.Relation;
        RefreshSelectedTab();
    }

    private void OnEventTabPressed()
    {
        _activeTab = StatusTab.Events;
        RefreshSelectedTab();
    }

    private void RefreshSelectedTab()
    {
        if (_selectedCharacterId == MasterSelectionId)
        {
            RefreshMasterTabContent();
            return;
        }

        if (_selectedCharacterId == 0 || !_repository.TryGet(_selectedCharacterId, out var character) || character is null)
        {
            UpdateTabButtons();
            return;
        }

        RefreshTabContent(character, _state.GetOrCreateCharacter(_selectedCharacterId));
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
                    case KeyAbility:
                        if (row.Length > 2 && int.TryParse(row[1], out var abilityId) && int.TryParse(row[2], out var abilityValue))
                        {
                            profile.Abilities[abilityId] = abilityValue;
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
        public Dictionary<int, int> Abilities { get; } = new();
    }
}
