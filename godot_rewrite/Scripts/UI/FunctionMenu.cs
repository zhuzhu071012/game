using System;
using Godot;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.UI;

public partial class FunctionMenu : Control
{
    private static readonly DateTime BaseDate = new(2021, 1, 17);

    private Label _statusLabel = null!;
    private Label _targetLabel = null!;
    private Label _hintLabel = null!;
    private Button _statusButton = null!;
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

    public override void _Ready()
    {
        UiThemeHelper.ApplyChineseTheme(this);
        _statusLabel = GetNode<Label>("Margin/Content/Header/Status");
        _targetLabel = GetNode<Label>("Margin/Content/TargetPanel/TargetText");
        _hintLabel = GetNode<Label>("Margin/Content/Footer/Hint");
        _statusButton = GetNode<Button>("Margin/Content/MenuGrid/StatusButton");
        _shopButton = GetNode<Button>("Margin/Content/MenuGrid/ShopButton");
        _restButton = GetNode<Button>("Margin/Content/MenuGrid/RestButton");
        _eventButton = GetNode<Button>("Margin/Content/MenuGrid/EventButton");
        _saveButton = GetNode<Button>("Margin/Content/SystemGrid/SaveButton");
        _loadButton = GetNode<Button>("Margin/Content/SystemGrid/LoadButton");
        _optionButton = GetNode<Button>("Margin/Content/SystemGrid/OptionButton");
        _helpButton = GetNode<Button>("Margin/Content/SystemGrid/HelpButton");
        _goOutButton = GetNode<Button>("Margin/Content/TravelRow/GoOutButton");
        _backButton = GetNode<Button>("Margin/Content/BottomBar/BackButton");

        _saveManager = new SaveManager();
        _state = SessionContext.ActiveState ?? new GameState();
        SessionContext.ActiveState = _state;
        _state.CurrentScene = "FunctionMenu";

        ApplyTexts();
        SaveActiveState();
    }

    private void ApplyTexts()
    {
        _statusLabel.Text = BuildStatusText();
        _targetLabel.Text = BuildTargetText();
        _hintLabel.Text = TextDb.Ui("function_menu.hint");

        _statusButton.Text = TextDb.Ui("function_menu.action_status");
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
        _loadButton.Disabled = false;
        _backButton.Disabled = false;
        _statusButton.Disabled = true;
        _restButton.Disabled = true;
        _eventButton.Disabled = true;
        _saveButton.Disabled = true;
        _optionButton.Disabled = true;
        _helpButton.Disabled = true;
        _goOutButton.Disabled = true;
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
        return _state.CurrentTargetCharacterId.HasValue
            ? TextDb.UiFormat("function_menu.target_selected", _state.CurrentTargetCharacterId.Value)
            : TextDb.Ui("function_menu.target_none");
    }

    private void OnShopPressed()
    {
        SaveActiveState();
        GetTree().ChangeSceneToFile("res://Scenes/Shop.tscn");
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
