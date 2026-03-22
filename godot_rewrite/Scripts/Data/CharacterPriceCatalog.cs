using System.Collections.Generic;

namespace EraKingdomRewrite.Scripts.Data;

public static class CharacterPriceCatalog
{
    private static readonly IReadOnlyDictionary<int, int> PriceByCharacterId = new Dictionary<int, int>
    {
        [101] = 1500,
        [102] = 1400,
        [103] = 1200,
        [104] = 1600,
        [105] = 1300,
        [106] = 1000,
        [107] = 3900,
        [108] = 4100,
        [109] = 3700,
        [110] = 4400,
        [111] = 3800,
        [112] = 4000
    };

    public static int GetPriceOrDefault(int characterId)
    {
        return PriceByCharacterId.TryGetValue(characterId, out var price) ? price : 0;
    }
}
