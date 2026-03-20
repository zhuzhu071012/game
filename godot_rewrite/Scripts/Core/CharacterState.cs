using System;
using System.Collections.Generic;
namespace EraKingdomRewrite.Scripts.Core;
public enum FallStage
{
	None = 0,
	Love = 1,
	Obedience = 2,
	Lust = 3,
	DeepLove = 4,
	Slave = 5,
	Consort = 6
}
public sealed class CharacterState
{
	public int CharacterId { get; set; }
	public bool IsUnlocked { get; set; }
	public bool IsOwned { get; set; }
	public bool HasMet { get; set; }
	public int RelationToPlayer { get; set; } = 100;
	public int Dependency { get; set; }
	public int Stress { get; set; }
	public int Mood { get; set; }
	public FallStage CurrentFallStage { get; set; } = FallStage.None;
	public HashSet<FallStage> ReachedFallStages { get; set; } = new();
	public Dictionary<int, int> BaseStats { get; set; } = new();
	public Dictionary<int, int> Abilities { get; set; } = new();
	public Dictionary<int, int> Marks { get; set; } = new();
	public Dictionary<int, int> Experience { get; set; } = new();
	public Dictionary<string, int> LocalFlags { get; set; } = new(StringComparer.Ordinal);
	public HashSet<string> ActiveTraits { get; set; } = new(StringComparer.Ordinal);
	public HashSet<string> TriggeredStoryIds { get; set; } = new(StringComparer.Ordinal);
	public bool HasReached(FallStage stage) => ReachedFallStages.Contains(stage);
	public void ReachStage(FallStage stage)
	{
		CurrentFallStage = stage;
		ReachedFallStages.Add(stage);
	}
	public int GetAbility(int id) => Abilities.TryGetValue(id, out var value) ? value : 0;
	public int GetMark(int id) => Marks.TryGetValue(id, out var value) ? value : 0;
	public int GetExperience(int id) => Experience.TryGetValue(id, out var value) ? value : 0;
	public static CharacterState CreateDefault(int characterId)
	{
		return new CharacterState
		{
			CharacterId = characterId
		};
	}
}
