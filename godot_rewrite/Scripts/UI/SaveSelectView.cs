using Godot;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.UI;

public partial class SaveSelectView : Control
{
    private Label _titleLabel = null!;
    private Label _tipLabel = null!;
    private VBoxContainer _slotList = null!;
    private Button _backButton = null!;

    private SaveManager _saveManager = null!;
    private string _mode = "new";

    public override void _Ready()
    {
        UiThemeHelper.ApplyChineseTheme(this);
        _titleLabel = GetNode<Label>("Margin/Content/Header/Title");
        _tipLabel = GetNode<Label>("Margin/Content/Header/Tip");
        _slotList = GetNode<VBoxContainer>("Margin/Content/SlotPanel/SlotMargin/SlotList");
        _backButton = GetNode<Button>("Margin/Content/BottomBar/Back");

        _saveManager = new SaveManager();
        _mode = SessionContext.PendingMenuMode;

        _backButton.Text = TextDb.Ui("save_select.back");
        UpdateHeader();
        BuildSlots();
    }

    private void UpdateHeader()
    {
        if (_mode == "load")
        {
            _titleLabel.Text = TextDb.Ui("save_select.load_title");
            _tipLabel.Text = TextDb.Ui("save_select.load_tip");
        }
        else
        {
            _titleLabel.Text = TextDb.Ui("save_select.new_title");
            _tipLabel.Text = TextDb.Ui("save_select.new_tip");
        }
    }

    private void BuildSlots()
    {
        foreach (var child in _slotList.GetChildren())
        {
            child.QueueFree();
        }

        foreach (var summary in _saveManager.GetSlotSummaries())
        {
            var button = new Button
            {
                Text = TextDb.UiFormat("save_select.slot_format", summary.Slot, summary.Title, summary.Detail),
                Alignment = HorizontalAlignment.Left,
                SizeFlagsHorizontal = SizeFlags.ExpandFill,
                CustomMinimumSize = new Vector2(0, 78)
            };

            button.Disabled = _mode == "load" && !summary.Exists;
            var slot = summary.Slot;
            button.Pressed += () => SelectSlot(slot);
            _slotList.AddChild(button);
        }
    }

    private void SelectSlot(int slot)
    {
        var state = _mode == "load" ? _saveManager.LoadOrCreate(slot) : CreateNewGameState();
        SessionContext.ActiveSlot = slot;
        SessionContext.ActiveState = state;

        _saveManager.Save(state, slot);

        if (_mode == "load" && state.GlobalFlags.TryGetValue("intro_finished", out var introFinished) && introFinished == 1)
        {
            var nextScene = state.CurrentScene switch
            {
                "Shop" => "res://Scenes/Shop.tscn",
                _ => "res://Scenes/FunctionMenu.tscn"
            };
            GetTree().ChangeSceneToFile(nextScene);
            return;
        }

        GetTree().ChangeSceneToFile("res://Scenes/StoryScene.tscn");
    }

    private static GameState CreateNewGameState()
    {
        var state = new GameState
        {
            CurrentScene = "StoryScene",
            Day = 1,
            TimeSlot = 0,
            Money = 5000
        };

        state.UnlockedPools.Clear();
        state.UnlockPool("wei");
        return state;
    }

    private void OnBackPressed()
    {
        GetTree().ChangeSceneToFile("res://Scenes/MainMenu.tscn");
    }
}
