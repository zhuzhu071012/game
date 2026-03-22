namespace EraKingdomRewrite.Scripts.Core;

public sealed class EventLogEntry
{
    public long Sequence { get; set; }
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Detail { get; set; } = string.Empty;
    public string Scene { get; set; } = string.Empty;
    public int Day { get; set; }
    public int TimeSlot { get; set; }
}
