using System;
using System.Collections.Generic;
using System.Linq;
using EraKingdomRewrite.Scripts.Core;
namespace EraKingdomRewrite.Scripts.Data;
public sealed class CharacterRepository
{
    private readonly Dictionary<int, CharacterData> _characters = new();
    public IReadOnlyCollection<CharacterData> All => _characters.Values;
    public void Register(CharacterData character)
    {
        _characters[character.No] = character;
    }
    public bool TryGet(int characterId, out CharacterData? character)
    {
        return _characters.TryGetValue(characterId, out character);
    }
    public CharacterData GetRequired(int characterId)
    {
        if (!_characters.TryGetValue(characterId, out var character))
        {
            throw new InvalidOperationException($"Character {characterId} is not registered.");
        }
        return character;
    }
    public IEnumerable<CharacterData> GetUnlockedForShop(GameState state)
    {
        return _characters.Values
            .Where(character => string.IsNullOrWhiteSpace(character.PoolId) || state.IsPoolUnlocked(character.PoolId))
            .OrderBy(character => character.No);
    }
    public void SeedDefaults(IEnumerable<CharacterData> characters)
    {
        foreach (var character in characters)
        {
            Register(character);
        }
    }
}
