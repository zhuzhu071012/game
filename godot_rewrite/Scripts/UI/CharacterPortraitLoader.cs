using System.Collections.Generic;
using System.IO;
using Godot;

namespace EraKingdomRewrite.Scripts.UI;

public static class CharacterPortraitLoader
{
    public static Texture2D? LoadPortrait(int portraitId)
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
                image.GenerateMipmaps();
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
        yield return Path.Combine(ProjectSettings.GlobalizePath("res://"), "Resources", "portraits", fileName);
        yield return Path.Combine(ResolveOriginalResourceRoot(), fileName);
    }

    private static string ResolveOriginalResourceRoot()
    {
        var projectRoot = ProjectSettings.GlobalizePath("res://").TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        var originalRoot = Directory.GetParent(projectRoot)?.FullName
            ?? throw new DirectoryNotFoundException("Cannot resolve original project root.");
        return Path.Combine(originalRoot, "resources");
    }
}
