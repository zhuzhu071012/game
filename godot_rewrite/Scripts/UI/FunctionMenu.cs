using System;
using System.Linq;
using Godot;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Data;
using EraKingdomRewrite.Scripts.Story;
using EraKingdomRewrite.Scripts.Text;
using EraKingdomRewrite.Scripts.Training;

namespace EraKingdomRewrite.Scripts.UI;

public partial class FunctionMenu : Control
{
    private static readonly DateTime BaseDate = new(2021, 1, 17);

    private Label _titleLabel = null!;
    private Label _subtitleLabel = null!;
    private Label _statusLabel = null!;
    private Label _targetTitleLabel = null!;
    private Label _targetLabel = null!;
    private Label _hintLabel = null!;
    private Button _statusButton = null!;
    private Button _trainingButton = null!;
    private Button _shopButton = null!;
    private Button _restButton = null!;
    private Button _eventButton = null!;
    private Button _saveButton = null!;
    private Button _loadButton = null!;
    private Button _optionButton = null!;
    private Button _helpButton = null!;
    private Button _goOutButton = null!;
    private Button _backButton = null!;

    private SaveManager _saveManager = null!;
    private GameState _state = null!;
    private CharacterRepository _repository = null!;
    private string _defaultHintText = string.Empty;

    public override void _Ready()
    {
        UiThemeHelper.ApplyChineseTheme(this);
        _titleLabel = GetNode<Label>("Margin/Content/TitlePanel/TitleBox/Title");
        _subtitleLabel = GetNode<Label>("Margin/Content/TitlePanel/TitleBox/Subtitle");
        _statusLabel = GetNode<Label>("Margin/Content/HeaderPanel/HeaderMargin/Status");
        _targetTitleLabel = GetNode<Label>("Margin/Content/TargetPanel/TargetMargin/TargetBox/TargetTitle");
        _targetLabel = GetNode<Label>("Margin/Content/TargetPanel/TargetMargin/TargetBox/TargetText");
        _hintLabel = GetNode<Label>("Margin/Content/FooterPanel/FooterMargin/Hint");
        _statusButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/MenuGrid/StatusButton");
        _trainingButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/MenuGrid/TrainingButton");
        _shopButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/MenuGrid/ShopButton");
        _restButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/MenuGrid/RestButton");
        _eventButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/MenuGrid/EventButton");
        _saveButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/SystemGrid/SaveButton");
        _loadButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/SystemGrid/LoadButton");
        _optionButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/SystemGrid/OptionButton");
        _helpButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/SystemGrid/HelpButton");
        _goOutButton = GetNode<Button>("Margin/Content/ChoicePanel/ChoiceMargin/ChoiceBox/TravelRow/GoOutButton");
        _backButton = GetNode<Button>("Margin/Content/BottomBar/BackButton");

        _saveManager = new SaveManager();
        _state = SessionContext.ActiveState ?? new GameState();
        _repository = new CharacterRepository();
        _repository.SeedDefaults(new CsvLoader().LoadDefaultRoster());
        SessionContext.ActiveState = _state;
        _state.CurrentScene = "FunctionMenu";
        _defaultHintText = TextDb.Ui("function_menu.hint");

        ApplyTexts();
        SaveActiveState();
    }

    private void ApplyTexts()
    {
        _titleLabel.Text = TextDb.Ui("function_menu.title");
        _subtitleLabel.Text = TextDb.Ui("function_menu.subtitle");
        _targetTitleLabel.Text = TextDb.Ui("function_menu.focus_title");
        _statusButton.Text = TextDb.Ui("function_menu.action_status");
        _trainingButton.Text = TextDb.Ui("function_menu.action_training");
        _shopButton.Text = TextDb.Ui("function_menu.action_shop");
        _restButton.Text = TextDb.Ui("function_menu.action_rest");
        _eventButton.Text = TextDb.Ui("function_menu.action_event");
        _saveButton.Text = TextDb.Ui("function_menu.action_save");
        _loadButton.Text = TextDb.Ui("function_menu.action_load");
        _optionButton.Text = TextDb.Ui("function_menu.action_option");
        _helpButton.Text = TextDb.Ui("function_menu.action_help");
        _goOutButton.Text = TextDb.Ui("function_menu.action_go_out");
        _backButton.Text = TextDb.Ui("function_menu.back");

        _shopButton.Disabled = false;
        _statusButton.Disabled = false;
        _trainingButton.Disabled = false;
        _restButton.Disabled = false;
        _eventButton.Disabled = false;
        _saveButton.Disabled = false;
        _loadButton.Disabled = false;
        _backButton.Disabled = false;
        _optionButton.Disabled = true;
        _helpButton.Disabled = true;
        _goOutButton.Disabled = true;

        RefreshOverview();
    }

    private string BuildStatusText()
    {
        var date = BaseDate.AddDays(Math.Max(0, _state.Day - 1));
        var masterName = TextDb.Ui("function_menu.master_name");
        var period = _state.TimeSlot == 0 ? TextDb.Ui("common.daytime") : TextDb.Ui("common.nighttime");
        var week = TextDb.Ui($"weekday.{(int)date.DayOfWeek}");
        return TextDb.UiFormat(
            "function_menu.status_line",
            masterName,
            _state.Day,
            period,
            date.Month,
            date.Day,
            week,
            _state.Money);
    }

    private string BuildTargetText()
    {
        if (!_state.CurrentTargetCharacterId.HasValue)
        {
            return TextDb.Ui("function_menu.target_none");
        }

        var characterId = _state.CurrentTargetCharacterId.Value;
        if (!_repository.TryGet(characterId, out var character) || character is null)
        {
            return TextDb.UiFormat("function_menu.target_missing", characterId);
        }

        var faction = string.IsNullOrWhiteSpace(character.Faction) ? TextDb.Ui("shop.faction_unknown") : character.Faction;
        var job = string.IsNullOrWhiteSpace(character.Job) ? "-" : character.Job;
        var difficulty = string.IsNullOrWhiteSpace(character.Difficulty) ? "-" : character.Difficulty;
        var persona = string.IsNullOrWhiteSpace(character.Persona) ? "-" : character.Persona;
        return TextDb.UiFormat("function_menu.target_overview_format", character.Name, faction, job, difficulty, persona);
    }

    private void RefreshOverview(string? hint = null)
    {
        _statusLabel.Text = BuildStatusText();
        _targetLabel.Text = BuildTargetText();
        _hintLabel.Text = hint ?? _defaultHintText;
    }

    private void OnShopPressed()
    {
        SaveActiveState();
        GetTree().ChangeSceneToFile("res://Scenes/Shop.tscn");
    }

    private void OnStatusPressed()
    {
        SaveActiveState();
        GetTree().ChangeSceneToFile("res://Scenes/CharacterStatus.tscn");
    }

    private void OnTrainingPressed()
    {
        if (!_state.CurrentTargetCharacterId.HasValue)
        {
            RefreshOverview(TextDb.Ui("function_menu.hint_training_no_target"));
            return;
        }

        var characterState = _state.GetOrCreateCharacter(_state.CurrentTargetCharacterId.Value);
        if (!characterState.IsOwned)
        {
            RefreshOverview(TextDb.Ui("function_menu.hint_training_not_owned"));
            return;
        }

        SaveActiveState();
        GetTree().ChangeSceneToFile("res://Scenes/Training.tscn");
    }

    private void OnRestPressed()
    {
        if (_state.TimeSlot == 0)
        {
            _state.TimeSlot = 1;
            _state.AddGlobalEvent(
                $"rest.day_to_night.{_state.Day}",
                TextDb.Ui("event_log.rest_night_title"),
                TextDb.Ui("event_log.rest_night_detail"));
            RefreshOverview(TextDb.Ui("function_menu.hint_rest_night"));
        }
        else
        {
            _state.TimeSlot = 0;
            _state.Day += 1;
            _state.AddGlobalEvent(
                $"rest.new_day.{_state.Day}",
                TextDb.Ui("event_log.rest_new_day_title"),
                TextDb.UiFormat("event_log.rest_new_day_detail", _state.Day));
            RefreshOverview(TextDb.Ui("function_menu.hint_rest_new_day"));
        }

        SaveActiveState();
    }

    private void OnEventPressed()
    {
        if (!_state.CurrentTargetCharacterId.HasValue)
        {
            RefreshOverview(TextDb.Ui("function_menu.hint_event_no_target"));
            return;
        }

        var nextEvent = new DailyEventFactory().CreateNextEvent(_state, _repository);
        if (nextEvent is null)
        {
            RefreshOverview(TextDb.Ui("function_menu.hint_event_none_available"));
            return;
        }

        var result = new StoryRunner().Trigger(nextEvent, _state);
        if (!result.WasTriggered)
        {
            RefreshOverview(TextDb.Ui("function_menu.hint_event_none_available"));
            return;
        }

        SessionContext.PendingStoryRequest = new StoryPlaybackRequest
        {
            StoryId = result.StoryId,
            Title = nextEvent.Title,
            Lines = result.Lines.ToList(),
            ReturnScene = "res://Scenes/FunctionMenu.tscn",
            ReturnSceneName = "FunctionMenu",
            SkipText = TextDb.Ui("story.skip_event"),
            FinishText = TextDb.Ui("story.finish_event")
        };
        SaveActiveState();
        GetTree().ChangeSceneToFile("res://Scenes/StoryScene.tscn");
    }

    private void OnSavePressed()
    {
        SessionContext.PendingMenuMode = "save";
        SaveActiveState();
        GetTree().ChangeSceneToFile("res://Scenes/SaveSelect.tscn");
    }

    private void OnLoadPressed()
    {
        SessionContext.PendingMenuMode = "load";
        SaveActiveState();
        GetTree().ChangeSceneToFile("res://Scenes/SaveSelect.tscn");
    }

    private void OnBackPressed()
    {
        SaveActiveState();
        GetTree().ChangeSceneToFile("res://Scenes/MainMenu.tscn");
    }

    private void SaveActiveState()
    {
        if (SessionContext.ActiveSlot > 0)
        {
            _saveManager.Save(_state, SessionContext.ActiveSlot);
        }
    }
}
