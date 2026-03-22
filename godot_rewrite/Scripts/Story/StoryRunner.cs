using System;
using System.Collections.Generic;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Text;

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
		if (storyEvent.Condition.CharacterId.HasValue)
		{
			state.GetOrCreateCharacter(storyEvent.Condition.CharacterId.Value).TriggeredStoryIds.Add(storyEvent.Id);
			state.AddCharacterEvent(
				storyEvent.Condition.CharacterId.Value,
				$"story.trigger.{storyEvent.Id}",
				TextDb.UiFormat("event_log.story_triggered_title", storyEvent.Title),
				TextDb.UiFormat("event_log.story_triggered_detail", storyEvent.Id));
		}
		else
		{
			state.AddGlobalEvent(
				$"story.trigger.{storyEvent.Id}",
				TextDb.UiFormat("event_log.story_triggered_title", storyEvent.Title),
				TextDb.UiFormat("event_log.story_triggered_detail", storyEvent.Id));
		}

		var appliedActions = new List<StoryAction>();
		var completedStoryIds = new List<string>();

		foreach (var action in storyEvent.Actions)
		{
			ApplyAction(action, state, completedStoryIds);
			appliedActions.Add(action);
		}

		foreach (var storyId in completedStoryIds)
		{
			var title = storyId == storyEvent.Id ? storyEvent.Title : storyId;
			if (storyEvent.Condition.CharacterId.HasValue)
			{
				state.AddCharacterEvent(
					storyEvent.Condition.CharacterId.Value,
					$"story.complete.{storyId}",
					TextDb.UiFormat("event_log.story_completed_title", title),
					TextDb.UiFormat("event_log.story_completed_detail", storyId));
			}
			else
			{
				state.AddGlobalEvent(
					$"story.complete.{storyId}",
					TextDb.UiFormat("event_log.story_completed_title", title),
					TextDb.UiFormat("event_log.story_completed_detail", storyId));
			}
		}

		return StoryResult.Triggered(storyEvent.Id, storyEvent.Lines, appliedActions);
	}

	private static void ApplyAction(StoryAction action, GameState state, ICollection<string> completedStoryIds)
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
				completedStoryIds.Add(action.StringValue);
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
			case StoryActionType.OwnCharacter:
			{
				var characterState = state.GetOrCreateCharacter(action.IntValue);
				characterState.IsOwned = true;
				characterState.IsUnlocked = true;
				characterState.HasMet = true;
				break;
			}
			case StoryActionType.SetCurrentTargetCharacter:
				if (action.IntValue > 0)
				{
					state.CurrentTargetCharacterId = action.IntValue;
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
