using System;
using System.Collections.Generic;
using EraKingdomRewrite.Scripts.Core;

namespace EraKingdomRewrite.Scripts.Story;

public sealed class StoryRunner
{
	public bool CanTrigger(StoryEvent storyEvent, GameState state)
	{
		if (storyEvent.TriggerOnce && state.HasTriggeredStory(storyEvent.Id))
		{
			return false;
		}

		return storyEvent.Condition.Evaluate(state);
	}

	public StoryResult Trigger(StoryEvent storyEvent, GameState state)
	{
		if (!CanTrigger(storyEvent, state))
		{
			return StoryResult.NotTriggered(storyEvent.Id);
		}

		state.TriggeredStoryIds.Add(storyEvent.Id);
		var appliedActions = new List<StoryAction>();

		foreach (var action in storyEvent.Actions)
		{
			ApplyAction(action, state);
			appliedActions.Add(action);
		}

		return StoryResult.Triggered(storyEvent.Id, storyEvent.Lines, appliedActions);
	}

	private static void ApplyAction(StoryAction action, GameState state)
	{
		switch (action.Type)
		{
			case StoryActionType.UnlockPool:
				state.UnlockPool(action.StringValue);
				break;
			case StoryActionType.SetGlobalFlag:
				state.GlobalFlags[action.StringValue] = action.IntValue;
				break;
			case StoryActionType.AddMoney:
				state.Money += action.IntValue;
				break;
			case StoryActionType.CompleteStory:
				state.CompletedStoryIds.Add(action.StringValue);
				break;
			case StoryActionType.UnlockCharacter:
				state.GetOrCreateCharacter(action.IntValue).IsUnlocked = true;
				break;
			case StoryActionType.SetCurrentScene:
				if (!string.IsNullOrWhiteSpace(action.StringValue))
				{
					state.CurrentScene = action.StringValue;
				}
				break;
			case StoryActionType.None:
			default:
				break;
		}
	}
}

public sealed class StoryResult
{
	public string StoryId { get; init; } = string.Empty;
	public bool WasTriggered { get; init; }
	public IReadOnlyList<StoryLine> Lines { get; init; } = Array.Empty<StoryLine>();
	public IReadOnlyList<StoryAction> AppliedActions { get; init; } = Array.Empty<StoryAction>();

	public static StoryResult NotTriggered(string storyId) => new()
	{
		StoryId = storyId,
		WasTriggered = false
	};

	public static StoryResult Triggered(string storyId, IReadOnlyList<StoryLine> lines, IReadOnlyList<StoryAction> appliedActions) => new()
	{
		StoryId = storyId,
		WasTriggered = true,
		Lines = lines,
		AppliedActions = appliedActions
	};
}
