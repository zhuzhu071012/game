using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;
using Godot;

namespace EraKingdomRewrite.Scripts.Text;

public static class TextDb
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private static Dictionary<string, string>? _ui;
    private static List<StoryTextLine>? _storyIntro;

    public static string Ui(string key)
    {
        EnsureLoaded();
        if (_ui is not null && _ui.TryGetValue(key, out var value))
        {
            return value;
        }

        return key;
    }

    public static string UiFormat(string key, params object[] args)
    {
        return string.Format(Ui(key), args);
    }

    public static IReadOnlyList<StoryTextLine> StoryIntro()
    {
        EnsureLoaded();
        return _storyIntro ?? new List<StoryTextLine>();
    }

    private static void EnsureLoaded()
    {
        if (_ui is not null && _storyIntro is not null)
        {
            return;
        }

        var textRoot = Path.Combine(ProjectSettings.GlobalizePath("res://"), "Data", "Text");
        _ui = LoadUi(Path.Combine(textRoot, "ui.json"));
        _storyIntro = LoadStoryLines(Path.Combine(textRoot, "story_intro.json"));
    }

    private static Dictionary<string, string> LoadUi(string path)
    {
        if (!File.Exists(path))
        {
            GD.PushWarning($"UI text file not found: {path}");
            return new Dictionary<string, string>(StringComparer.Ordinal);
        }

        var json = File.ReadAllText(path);
        return JsonSerializer.Deserialize<Dictionary<string, string>>(json, JsonOptions)
            ?? new Dictionary<string, string>(StringComparer.Ordinal);
    }

    private static List<StoryTextLine> LoadStoryLines(string path)
    {
        if (!File.Exists(path))
        {
            GD.PushWarning($"Story text file not found: {path}");
            return new List<StoryTextLine>();
        }

        var json = File.ReadAllText(path);
        return JsonSerializer.Deserialize<List<StoryTextLine>>(json, JsonOptions) ?? new List<StoryTextLine>();
    }
}

public sealed class StoryTextLine
{
    public string Speaker { get; set; } = string.Empty;
    public string Text { get; set; } = string.Empty;
}
