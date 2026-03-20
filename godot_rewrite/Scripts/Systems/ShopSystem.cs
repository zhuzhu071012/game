using System.Linq;
using System.Text;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Data;

namespace EraKingdomRewrite.Scripts.Systems;

public sealed class ShopSystem
{
    public string BuildSummary(GameState state, CharacterRepository repository)
    {
        var sb = new StringBuilder();
        var wei = repository.All.Where(character => character.PoolId == "wei").OrderBy(character => character.No).ToList();
        var other = repository.All.Where(character => character.PoolId == "other").OrderBy(character => character.No).ToList();

        sb.AppendLine("Wei roster:");
        foreach (var character in wei)
        {
            sb.AppendLine($"- {character.No} {character.Name} / {character.Faction}");
        }

        sb.AppendLine();
        sb.AppendLine($"Other forces: {(state.IsPoolUnlocked("other") ? "Unlocked" : "Locked")}");
        foreach (var character in other)
        {
            var status = state.IsPoolUnlocked(character.PoolId) ? "Available" : "Locked";
            sb.AppendLine($"- {character.No} {character.Name} / {character.Faction} [{status}]");
        }

        return sb.ToString().TrimEnd();
    }
}
