using EraKingdomRewrite.Scripts.Story;

namespace EraKingdomRewrite.Scripts.Core;

public static class SessionContext
{
    public static GameState? ActiveState { get; set; }
    public static int ActiveSlot { get; set; }
    public static string PendingMenuMode { get; set; } = "new";
    public static StoryPlaybackRequest? PendingStoryRequest { get; set; }

    public static bool HasActiveState => ActiveState is not null;

    public static void Clear()
    {
        ActiveState = null;
        ActiveSlot = 0;
        PendingMenuMode = "new";
        PendingStoryRequest = null;
    }
}
