using System.Collections.Generic;
using System.Linq;
using Godot;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Story;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.UI;

public partial class StoryScene : Control
{
    private Label _titleLabel = null!;
    private RichTextLabel _storyLabel = null!;
    private Button _skipButton = null!;
    private Button _nextButton = null!;

    private SaveManager _saveManager = null!;
    private GameState _state = null!;
    private IReadOnlyList<StoryLine> _lines = null!;
    private int _index;

    public override void _Ready()
    {
        UiThemeHelper.ApplyChineseTheme(this);
        _titleLabel = GetNode<Label>("Margin/Content/Title");
        _storyLabel = GetNode<RichTextLabel>("Margin/Content/StoryPanel/StoryMargin/StoryText");
        _skipButton = GetNode<Button>("Margin/Content/Actions/SkipButton");
        _nextButton = GetNode<Button>("Margin/Content/Actions/NextButton");

        _saveManager = new SaveManager();
        _state = SessionContext.ActiveState ?? new GameState();
        SessionContext.ActiveState = _state;

        _titleLabel.Text = TextDb.Ui("story.title");
        _skipButton.Text = TextDb.Ui("story.skip");
        _nextButton.Text = TextDb.Ui("story.next");
        _storyLabel.Text = string.Empty;
        _lines = BuildIntroEvent().Lines;
        ShowCurrentLine();
    }

    private static StoryEvent BuildIntroEvent()
    {
        return new StoryEvent
        {
            Id = "intro_opening",
            Title = TextDb.Ui("story.title"),
            Lines = TextDb.StoryIntro().Select(line => new StoryLine
            {
                Speaker = line.Speaker,
                Text = line.Text
            }).ToList()
        };
    }

    private void ShowCurrentLine()
    {
        if (_index >= _lines.Count)
        {
            FinishIntro();
            return;
        }

        var line = _lines[_index];
        _storyLabel.Text = $"{line.Speaker}\n\n{line.Text}";
        _nextButton.Text = _index == _lines.Count - 1 ? TextDb.Ui("story.enter_shop") : TextDb.Ui("story.next");
    }

    private void OnNextPressed()
    {
        _index++;
        ShowCurrentLine();
    }

    private void OnSkipPressed()
    {
        FinishIntro();
    }

    private void FinishIntro()
    {
        _state.GlobalFlags["intro_finished"] = 1;
        _state.CurrentScene = "FunctionMenu";
        if (SessionContext.ActiveSlot > 0)
        {
            _saveManager.Save(_state, SessionContext.ActiveSlot);
        }

        GetTree().ChangeSceneToFile("res://Scenes/FunctionMenu.tscn");
    }
}
