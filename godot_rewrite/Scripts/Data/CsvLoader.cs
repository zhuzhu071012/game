using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using Godot;

namespace EraKingdomRewrite.Scripts.Data;

public sealed class CsvLoader
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    private const string KeyNo = "\u756a\u53f7";
    private const string KeyName = "\u540d\u524d";
    private const string KeyCallName = "\u547c\u3073\u540d";
    private const string KeyBase = "\u57fa\u790e";
    private const string KeyAbility = "\u80fd\u529b";
    private const string KeyTalent = "\u7d20\u8cea";
    private const string KeyExperience = "\u7d4c\u9a13";
    private const string KeyCstr = "CSTR";

    private static readonly IReadOnlyDictionary<int, string> CharacterPools = new Dictionary<int, string>
    {
        [101] = "wei",
        [102] = "wei",
        [103] = "wei",
        [104] = "wei",
        [105] = "wei",
        [106] = "wei",
        [107] = "other",
        [108] = "other",
        [109] = "other",
        [110] = "other",
        [111] = "other",
        [112] = "other"
    };

    private static readonly IReadOnlyDictionary<int, string> Factions = new Dictionary<int, string>
    {
        [101] = "\u9b4f",
        [102] = "\u9b4f",
        [103] = "\u9b4f",
        [104] = "\u9b4f",
        [105] = "\u9b4f",
        [106] = "\u9b4f",
        [107] = "\u8700",
        [108] = "\u5434",
        [109] = "\u8700",
        [110] = "\u7fa4",
        [111] = "\u8700",
        [112] = "\u5434"
    };

    public IEnumerable<string[]> LoadRawRows(string filePath)
    {
        foreach (var line in File.ReadLines(filePath, new UTF8Encoding(true)))
        {
            if (string.IsNullOrWhiteSpace(line) || line.StartsWith(';'))
            {
                continue;
            }

            yield return line.Split(',', StringSplitOptions.None);
        }
    }

    public IReadOnlyList<CharacterData> LoadDefaultRoster()
    {
        var charaRoot = ResolveOriginalCharaRoot();
        var characters = new List<CharacterData>();

        foreach (var characterId in CharacterPools.Keys.OrderBy(static id => id))
        {
            var generated = LoadGeneratedCharacter(characterId);
            if (generated is not null)
            {
                characters.Add(generated);
                continue;
            }

            var file = FindCharacterFile(charaRoot, characterId);
            if (file is null)
            {
                GD.PushWarning($"Character CSV not found for id {characterId}.");
                continue;
            }

            var character = LoadCharacter(file, characterId, CharacterPools[characterId]);
            characters.Add(character);
        }

        return characters;
    }

    private static string ResolveOriginalCharaRoot()
    {
        var projectRoot = ProjectSettings.GlobalizePath("res://").TrimEnd(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
        var originalRoot = Directory.GetParent(projectRoot)?.FullName
            ?? throw new DirectoryNotFoundException("Cannot resolve original project root.");
        return Path.Combine(originalRoot, "CSV", "Chara");
    }

    private static string ResolveCharacterProfilePath()
    {
        return Path.Combine(ProjectSettings.GlobalizePath("res://"), "Data", "Characters", "character_profiles.json");
    }

    private static string ResolveGeneratedCharacterPath(int characterId)
    {
        return Path.Combine(ProjectSettings.GlobalizePath("res://"), "Data", "Characters", $"{characterId}.json");
    }

    private static CharacterData? LoadGeneratedCharacter(int characterId)
    {
        var path = ResolveGeneratedCharacterPath(characterId);
        if (!File.Exists(path))
        {
            return null;
        }

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

        if (string.IsNullOrWhiteSpace(character.PoolId) && CharacterPools.TryGetValue(characterId, out var poolId))
        {
            character.PoolId = poolId;
        }

        if (string.IsNullOrWhiteSpace(character.Faction) && Factions.TryGetValue(characterId, out var faction))
        {
            character.Faction = faction;
        }

        if (string.IsNullOrWhiteSpace(character.CallName))
        {
            character.CallName = character.Name;
        }

        return character;
    }

    private static Dictionary<int, CharacterProfileRecord> LoadCharacterProfiles()
    {
        var path = ResolveCharacterProfilePath();
        if (!File.Exists(path))
        {
            GD.PushWarning($"Character profile file not found: {path}");
            return new Dictionary<int, CharacterProfileRecord>();
        }

        var json = File.ReadAllText(path);
        var raw = JsonSerializer.Deserialize<Dictionary<string, CharacterProfileRecord>>(json, JsonOptions)
            ?? new Dictionary<string, CharacterProfileRecord>();
        var result = new Dictionary<int, CharacterProfileRecord>();

        foreach (var pair in raw)
        {
            if (int.TryParse(pair.Key, out var id))
            {
                result[id] = pair.Value;
            }
        }

        return result;
    }

    private static void ApplyProfile(CharacterData character, IReadOnlyDictionary<int, CharacterProfileRecord> profiles)
    {
        if (!profiles.TryGetValue(character.No, out var profile))
        {
            return;
        }

        character.Difficulty = profile.Difficulty;
        character.Persona = profile.Persona;
        character.Job = profile.Job;
        character.PortraitId = profile.PortraitId;
    }

    private static string? FindCharacterFile(string charaRoot, int characterId)
    {
        var pattern = $"Chara{characterId}_*.csv";
        return Directory.EnumerateFiles(charaRoot, pattern, SearchOption.AllDirectories).FirstOrDefault();
    }

    private CharacterData LoadCharacter(string filePath, int characterId, string poolId)
    {
        var data = new CharacterData
        {
            No = characterId,
            PoolId = poolId,
            Faction = Factions.TryGetValue(characterId, out var faction) ? faction : string.Empty
        };

        foreach (var row in LoadRawRows(filePath))
        {
            if (row.Length == 0)
            {
                continue;
            }

            var key = row[0].Trim();
            switch (key)
            {
                case KeyNo:
                    data.No = ParseInt(row, 1);
                    break;
                case KeyName:
                    data.Name = GetString(row, 1);
                    break;
                case KeyCallName:
                    data.CallName = GetString(row, 1);
                    break;
                case KeyBase:
                    data.BaseStats[ParseInt(row, 1)] = ParseInt(row, 2);
                    break;
                case KeyAbility:
                    data.Abilities[ParseInt(row, 1)] = ParseInt(row, 2);
                    break;
                case KeyTalent:
                    var talent = GetString(row, 1);
                    if (!string.IsNullOrWhiteSpace(talent))
                    {
                        data.Talents.Add(talent);
                    }
                    break;
                case KeyExperience:
                    break;
                case KeyCstr:
                    data.Cstr[ParseInt(row, 1)] = GetString(row, 2);
                    break;
            }
        }

        if (string.IsNullOrWhiteSpace(data.CallName))
        {
            data.CallName = data.Name;
        }

        return data;
    }

    private static int ParseInt(string[] row, int index)
    {
        if (index >= row.Length)
        {
            return 0;
        }

        return int.TryParse(row[index], out var value) ? value : 0;
    }

    private static string GetString(string[] row, int index)
    {
        return index < row.Length ? row[index].Trim() : string.Empty;
    }
}

public sealed class CharacterProfileRecord
{
    public string Difficulty { get; set; } = string.Empty;
    public string Persona { get; set; } = string.Empty;
    public string Job { get; set; } = string.Empty;
    public int PortraitId { get; set; }
}
