using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace EraKingdomRewrite.Scripts.Data;

public sealed class CharacterData
{
    [JsonPropertyName("id")]
    public int No { get; set; }
    public string Name { get; set; } = string.Empty;
    public string CallName { get; set; } = string.Empty;
    public string Gender { get; set; } = string.Empty;
    public string Faction { get; set; } = string.Empty;
    public string PoolId { get; set; } = string.Empty;
    public string Difficulty { get; set; } = string.Empty;
    public string Persona { get; set; } = string.Empty;
    public string Job { get; set; } = string.Empty;
    public int PortraitId { get; set; }
    public int Price { get; set; }
    public Dictionary<int, int> BaseStats { get; set; } = new();
    public Dictionary<int, int> Abilities { get; set; } = new();
    public Dictionary<int, string> Cstr { get; set; } = new();
    public HashSet<string> Talents { get; set; } = new(StringComparer.Ordinal);

    public string GetProfileLine(int index) => Cstr.TryGetValue(index, out var value) ? value : string.Empty;

    public string GetGenderTag()
    {
        if (!string.IsNullOrWhiteSpace(Gender))
        {
            return Gender.Trim().ToLowerInvariant() switch
            {
                "male" or "man" or "m" or "男性" or "男" => "male",
                "female" or "woman" or "f" or "女性" or "女" => "female",
                _ => Gender.Trim()
            };
        }

        if (Talents.Contains("男性"))
        {
            return "male";
        }

        if (Talents.Contains("女性"))
        {
            return "female";
        }

        return "unknown";
    }

    public string GetSubjectPronoun()
    {
        return GetGenderTag() switch
        {
            "male" => "他",
            "female" => "她",
            _ => "TA"
        };
    }
}
