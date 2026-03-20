using System.IO;
using Godot;

namespace EraKingdomRewrite.Scripts.UI;

public static class UiThemeHelper
{
    public static void ApplyChineseTheme(Control root, int fontSize = 24)
    {
        var font = TryLoadFont();
        if (font is null)
        {
            GD.PushWarning("No usable Chinese font could be loaded for UI.");
            return;
        }

        var theme = new Theme
        {
            DefaultFont = font,
            DefaultFontSize = fontSize
        };

        root.Theme = theme;
    }

    private static FontFile? TryLoadFont()
    {
        var candidates = new[]
        {
            @"C:\Windows\Fonts\simhei.ttf",
            @"C:\Windows\Fonts\simsun.ttc",
            @"C:\Windows\Fonts\msyh.ttc"
        };

        foreach (var path in candidates)
        {
            if (!File.Exists(path))
            {
                continue;
            }

            var font = new FontFile();
            var error = font.LoadDynamicFont(path);
            if (error == Error.Ok)
            {
                return font;
            }

            GD.PushWarning($"Failed to load UI font: {path} ({error})");
        }

        return null;
    }
}
