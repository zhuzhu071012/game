using System;
using System.Collections.Generic;
namespace EraKingdomRewrite.Scripts.Core;
public sealed class GameState
{
	public string SaveVersion { get; set; } = "0.1.0";
	public string CurrentScene { get; set; } = "MainMenu";
	public int Day { get; set; } = 1;
	public int TimeSlot { get; set; }
	public int Money { get; set; } = 5000;
	public int MasterCharacterId { get; set; }
	public int? CurrentTargetCharacterId { get; set; }
	public int? CurrentAssistantCharacterId { get; set; }
	public HashSet<string> UnlockedPools { get; set; } = new(StringComparer.Ordinal)
	{
        "wei"
	};
	public HashSet<string> CompletedStoryIds { get; set; } = new(StringComparer.Ordinal);
	public HashSet<string> TriggeredStoryIds { get; set; } = new(StringComparer.Ordinal);
	public List<EventLogEntry> EventLog { get; set; } = new();
	public long EventLogSequence { get; set; }
	public Dictionary<int, CharacterState> Characters { get; set; } = new();
	public Dictionary<string, int> GlobalFlags { get; set; } = new(StringComparer.Ordinal);
	public bool IsPoolUnlocked(string poolId) => UnlockedPools.Contains(poolId);
	public void UnlockPool(string poolId)
	{
		if (!string.IsNullOrWhiteSpace(poolId))
		{
			UnlockedPools.Add(poolId);
		}
	}
	public CharacterState GetOrCreateCharacter(int characterId)
	{
		if (!Characters.TryGetValue(characterId, out var state))
		{
			state = CharacterState.CreateDefault(characterId);
			Characters[characterId] = state;
		}
		return state;
	}
	public EventLogEntry AddGlobalEvent(string id, string title, string detail = "")
	{
		return AddEvent(EventLog, id, title, detail);
	}
	public EventLogEntry AddCharacterEvent(int characterId, string id, string title, string detail = "")
	{
		return AddEvent(GetOrCreateCharacter(characterId).EventLog, id, title, detail);
	}
	public bool HasTriggeredStory(string storyId) => TriggeredStoryIds.Contains(storyId);
	public bool HasCompletedStory(string storyId) => CompletedStoryIds.Contains(storyId);
	private EventLogEntry AddEvent(ICollection<EventLogEntry> target, string id, string title, string detail)
	{
		var entry = new EventLogEntry
		{
			Sequence = ++EventLogSequence,
			Id = id,
			Title = title,
			Detail = detail,
			Scene = CurrentScene,
			Day = Day,
			TimeSlot = TimeSlot
		};
		target.Add(entry);
		return entry;
	}
}
