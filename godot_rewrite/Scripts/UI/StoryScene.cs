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
    private StoryEvent _introEvent = null!;
    private StoryPlaybackRequest? _request;
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
        _state.CurrentScene = "StoryScene";
        _storyLabel.Text = string.Empty;

        _request = SessionContext.PendingStoryRequest;
        if (_request is not null)
        {
            _titleLabel.Text = _request.Title;
            _skipButton.Text = string.IsNullOrWhiteSpace(_request.SkipText) ? TextDb.Ui("story.skip_event") : _request.SkipText;
            _nextButton.Text = TextDb.Ui("story.next");
            _lines = _request.Lines;
        }
        else
        {
            _titleLabel.Text = TextDb.Ui("story.title");
            _skipButton.Text = TextDb.Ui("story.skip");
            _nextButton.Text = TextDb.Ui("story.next");
            _introEvent = BuildIntroEvent();
            if (!_state.HasTriggeredStory(_introEvent.Id))
            {
                var result = new StoryRunner().Trigger(_introEvent, _state);
                _lines = result.WasTriggered ? result.Lines : _introEvent.Lines;
            }
            else
            {
                _lines = _introEvent.Lines;
            }
        }

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
            FinishCurrentStory();
            return;
        }

        var line = _lines[_index];
        _storyLabel.Text = $"{line.Speaker}\n\n{line.Text}";
        if (_index == _lines.Count - 1)
        {
            _nextButton.Text = _request is null
                ? TextDb.Ui("story.enter_shop")
                : string.IsNullOrWhiteSpace(_request.FinishText)
                    ? TextDb.Ui("story.finish_event")
                    : _request.FinishText;
            return;
        }

        _nextButton.Text = TextDb.Ui("story.next");
    }

    private void OnNextPressed()
    {
        _index++;
        ShowCurrentLine();
    }

    private void OnSkipPressed()
    {
        FinishCurrentStory();
    }

    private void FinishCurrentStory()
    {
        if (_request is not null)
        {
            FinishRuntimeStory();
            return;
        }

        FinishIntro();
    }

    private void FinishIntro()
    {
        _state.GlobalFlags["intro_finished"] = 1;
        if (!_state.HasCompletedStory(_introEvent.Id))
        {
            _state.CompletedStoryIds.Add(_introEvent.Id);
            _state.AddGlobalEvent(
                $"story.complete.{_introEvent.Id}",
                TextDb.UiFormat("event_log.story_completed_title", _introEvent.Title),
                TextDb.UiFormat("event_log.story_completed_detail", _introEvent.Id));
        }

        _state.CurrentScene = "FunctionMenu";
        if (SessionContext.ActiveSlot > 0)
        {
            _saveManager.Save(_state, SessionContext.ActiveSlot);
        }

        GetTree().ChangeSceneToFile("res://Scenes/FunctionMenu.tscn");
    }

    private void FinishRuntimeStory()
    {
        var nextScene = _request?.ReturnScene ?? "res://Scenes/FunctionMenu.tscn";
        var nextSceneName = _request?.ReturnSceneName ?? "FunctionMenu";
        SessionContext.PendingStoryRequest = null;
        _request = null;
        _state.CurrentScene = nextSceneName;
        if (SessionContext.ActiveSlot > 0)
        {
            _saveManager.Save(_state, SessionContext.ActiveSlot);
        }

        GetTree().ChangeSceneToFile(nextScene);
    }
}
