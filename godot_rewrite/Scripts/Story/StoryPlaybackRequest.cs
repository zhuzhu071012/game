using System.Collections.Generic;

namespace EraKingdomRewrite.Scripts.Story;

public sealed class StoryPlaybackRequest
{
    public string StoryId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public List<StoryLine> Lines { get; set; } = new();
    public string ReturnScene { get; set; } = "res://Scenes/FunctionMenu.tscn";
    public string ReturnSceneName { get; set; } = "FunctionMenu";
    public string SkipText { get; set; } = string.Empty;
    public string FinishText { get; set; } = string.Empty;
}
