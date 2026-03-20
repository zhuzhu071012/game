using System;
using System.Collections.Generic;

namespace EraKingdomRewrite.Scripts.Data;

public sealed class CharacterData
{
    public int No { get; set; }
    public string Name { get; set; } = string.Empty;
    public string CallName { get; set; } = string.Empty;
    public string Faction { get; set; } = string.Empty;
    public string PoolId { get; set; } = string.Empty;
    public string Difficulty { get; set; } = string.Empty;
    public string Persona { get; set; } = string.Empty;
    public string Job { get; set; } = string.Empty;
    public int PortraitId { get; set; }
    public Dictionary<int, int> BaseStats { get; set; } = new();
    public Dictionary<int, int> Abilities { get; set; } = new();
    public Dictionary<int, string> Cstr { get; set; } = new();
    public HashSet<string> Talents { get; set; } = new(StringComparer.Ordinal);

    public string GetProfileLine(int index) => Cstr.TryGetValue(index, out var value) ? value : string.Empty;
}
