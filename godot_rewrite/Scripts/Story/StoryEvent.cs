using System;
using System.Collections.Generic;
using EraKingdomRewrite.Scripts.Core;

namespace EraKingdomRewrite.Scripts.Story;

public sealed class StoryEvent
{
	public string Id { get; set; } = string.Empty;
	public string Title { get; set; } = string.Empty;
	public bool TriggerOnce { get; set; } = true;
	public int Priority { get; set; }

	public StoryCondition Condition { get; set; } = new();
	public List<StoryLine> Lines { get; set; } = new();
	public List<StoryAction> Actions { get; set; } = new();
}

public sealed class StoryCondition
{
	public HashSet<string> RequiredGlobalFlags { get; set; } = new(StringComparer.Ordinal);
	public HashSet<string> ForbiddenGlobalFlags { get; set; } = new(StringComparer.Ordinal);
	public HashSet<string> RequiredCompletedStoryIds { get; set; } = new(StringComparer.Ordinal);
	public HashSet<string> ForbiddenTriggeredStoryIds { get; set; } = new(StringComparer.Ordinal);

	public string? RequiredUnlockedPoolId { get; set; }
	public int? CharacterId { get; set; }
	public FallStage? RequiredFallStage { get; set; }
	public int? MinDay { get; set; }
	public int? MaxDay { get; set; }

	public bool Evaluate(GameState state)
	{
		if (RequiredUnlockedPoolId is not null && !state.IsPoolUnlocked(RequiredUnlockedPoolId))
		{
			return false;
		}

		if (MinDay.HasValue && state.Day < MinDay.Value)
		{
			return false;
		}

		if (MaxDay.HasValue && state.Day > MaxDay.Value)
		{
			return false;
		}

		foreach (var flag in RequiredGlobalFlags)
		{
			if (!state.GlobalFlags.ContainsKey(flag))
			{
				return false;
			}
		}

		foreach (var flag in ForbiddenGlobalFlags)
		{
			if (state.GlobalFlags.ContainsKey(flag))
			{
				return false;
			}
		}

		foreach (var storyId in RequiredCompletedStoryIds)
		{
			if (!state.HasCompletedStory(storyId))
			{
				return false;
			}
		}

		foreach (var storyId in ForbiddenTriggeredStoryIds)
		{
			if (state.HasTriggeredStory(storyId))
			{
				return false;
			}
		}

		if (CharacterId.HasValue && RequiredFallStage.HasValue)
		{
			var character = state.GetOrCreateCharacter(CharacterId.Value);
			if (!character.HasReached(RequiredFallStage.Value))
			{
				return false;
			}
		}

		return true;
	}
}

public sealed class StoryLine
{
	public string Speaker { get; set; } = string.Empty;
	public string Text { get; set; } = string.Empty;
}

public sealed class StoryAction
{
	public StoryActionType Type { get; set; } = StoryActionType.None;
	public string StringValue { get; set; } = string.Empty;
	public int IntValue { get; set; }
}

public enum StoryActionType
{
	None = 0,
	UnlockPool = 1,
	SetGlobalFlag = 2,
	AddMoney = 3,
	CompleteStory = 4,
	UnlockCharacter = 5,
	SetCurrentScene = 6
}
