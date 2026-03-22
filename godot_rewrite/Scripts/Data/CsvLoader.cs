using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.Json;
using Godot;

namespace EraKingdomRewrite.Scripts.Data;

public sealed class CsvLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public IReadOnlyList<CharacterData> LoadDefaultRoster()
    {
        var charactersRoot = Path.Combine(ProjectSettings.GlobalizePath("res://"), "Data", "Characters");
        if (!Directory.Exists(charactersRoot))
        {
            GD.PushWarning($"Character data directory not found: {charactersRoot}");
            return new List<CharacterData>();
        }

        return Directory.EnumerateFiles(charactersRoot, "*.json", SearchOption.TopDirectoryOnly)
            .Select(static path => new { Path = path, Id = ParseCharacterId(path) })
            .Where(static item => item.Id.HasValue)
            .OrderBy(static item => item.Id!.Value)
            .Select(static item => LoadGeneratedCharacter(item.Path, item.Id!.Value))
            .Where(static character => character is not null)
            .Cast<CharacterData>()
            .ToList();
    }

    private static int? ParseCharacterId(string path)
    {
        return int.TryParse(Path.GetFileNameWithoutExtension(path), out var characterId) ? characterId : null;
    }

    private static CharacterData? LoadGeneratedCharacter(string path, int characterId)
    {
        var json = File.ReadAllText(path);
        var character = JsonSerializer.Deserialize<CharacterData>(json, JsonOptions);
        if (character is null)
        {
            GD.PushWarning($"Failed to deserialize generated character file: {path}");
            return null;
        }

        if (character.No == 0)
        {
            character.No = characterId;
        }

        if (string.IsNullOrWhiteSpace(character.CallName))
        {
            character.CallName = character.Name;
        }

        if (string.IsNullOrWhiteSpace(character.Gender))
        {
            character.Gender = character.GetGenderTag();
        }

        if (character.Price <= 0)
        {
            character.Price = CharacterPriceCatalog.GetPriceOrDefault(character.No);
        }

        return character;
    }
}
