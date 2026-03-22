using System.Collections.Generic;
using System.Linq;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Data;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.Story;

public sealed class DailyEventFactory
{
    public StoryEvent? CreateNextEvent(GameState state, CharacterRepository repository)
    {
        if (!state.CurrentTargetCharacterId.HasValue)
        {
            return null;
        }

        var characterId = state.CurrentTargetCharacterId.Value;
        if (!repository.TryGet(characterId, out var character) || character is null)
        {
            return null;
        }

        var candidates = new List<StoryEvent>
        {
            CreateFirstContactEvent(character),
            CreateDayObservationEvent(character),
            CreateNightObservationEvent(character)
        };

        var runner = new StoryRunner();
        return candidates
            .OrderByDescending(static storyEvent => storyEvent.Priority)
            .FirstOrDefault(storyEvent => runner.CanTrigger(storyEvent, state));
    }

    private static StoryEvent CreateFirstContactEvent(CharacterData character)
    {
        return new StoryEvent
        {
            Id = $"daily.{character.No}.first_contact",
            Title = TextDb.UiFormat("story_event.first_contact_title", character.Name),
            TriggerOnce = true,
            Priority = 100,
            Condition = new StoryCondition
            {
                CharacterId = character.No,
                RequireCurrentTargetCharacter = true,
                RequiredHasMet = true
            },
            Lines = BuildFirstContactLines(character),
            Actions = new List<StoryAction>
            {
                new()
                {
                    Type = StoryActionType.CompleteStory,
                    StringValue = $"daily.{character.No}.first_contact"
                }
            }
        };
    }

    private static StoryEvent CreateDayObservationEvent(CharacterData character)
    {
        return new StoryEvent
        {
            Id = $"daily.{character.No}.day_observation",
            Title = TextDb.UiFormat("story_event.day_observation_title", character.Name),
            TriggerOnce = false,
            Priority = 20,
            Condition = new StoryCondition
            {
                CharacterId = character.No,
                RequireCurrentTargetCharacter = true,
                RequiredHasMet = true,
                RequiredTimeSlot = 0
            },
            Lines = BuildObservationLines(character, false)
        };
    }

    private static StoryEvent CreateNightObservationEvent(CharacterData character)
    {
        return new StoryEvent
        {
            Id = $"daily.{character.No}.night_observation",
            Title = TextDb.UiFormat("story_event.night_observation_title", character.Name),
            TriggerOnce = false,
            Priority = 30,
            Condition = new StoryCondition
            {
                CharacterId = character.No,
                RequireCurrentTargetCharacter = true,
                RequiredHasMet = true,
                RequiredTimeSlot = 1
            },
            Lines = BuildObservationLines(character, true)
        };
    }

    private static List<StoryLine> BuildFirstContactLines(CharacterData character)
    {
        var pronoun = character.GetSubjectPronoun();
        return new List<StoryLine>
        {
            new()
            {
                Speaker = TextDb.Ui("story_event.narrator"),
                Text = TextDb.UiFormat("story_event.first_contact_line_1", character.Name, GetFactionText(character), GetJobText(character), pronoun)
            },
            new()
            {
                Speaker = character.Name,
                Text = TextDb.UiFormat("story_event.first_contact_line_2", BuildProfileHook(character))
            },
            new()
            {
                Speaker = TextDb.Ui("story_event.narrator"),
                Text = TextDb.UiFormat("story_event.first_contact_line_3", character.Name, pronoun, GetPersonaText(character))
            }
        };
    }

    private static List<StoryLine> BuildObservationLines(CharacterData character, bool isNight)
    {
        var prefixKey = isNight ? "story_event.night_observation" : "story_event.day_observation";
        return new List<StoryLine>
        {
            new()
            {
                Speaker = TextDb.Ui("story_event.narrator"),
                Text = TextDb.UiFormat($"{prefixKey}_line_1", character.Name, GetDifficultyText(character))
            },
            new()
            {
                Speaker = character.Name,
                Text = TextDb.UiFormat($"{prefixKey}_line_2", BuildProfileHook(character))
            },
            new()
            {
                Speaker = TextDb.Ui("story_event.narrator"),
                Text = TextDb.UiFormat($"{prefixKey}_line_3", character.Name, GetPersonaText(character))
            }
        };
    }

    private static string BuildProfileHook(CharacterData character)
    {
        var profileLine = Enumerable.Range(92, 7)
            .Select(character.GetProfileLine)
            .FirstOrDefault(static line => !string.IsNullOrWhiteSpace(line));
        if (!string.IsNullOrWhiteSpace(profileLine))
        {
            return profileLine;
        }

        return TextDb.UiFormat("story_event.profile_fallback", GetFactionText(character), GetJobText(character), GetPersonaText(character));
    }

    private static string GetFactionText(CharacterData character)
    {
        return string.IsNullOrWhiteSpace(character.Faction) ? TextDb.Ui("shop.faction_unknown") : character.Faction;
    }

    private static string GetJobText(CharacterData character)
    {
        return string.IsNullOrWhiteSpace(character.Job) ? TextDb.Ui("story_event.unknown_job") : character.Job;
    }

    private static string GetPersonaText(CharacterData character)
    {
        return string.IsNullOrWhiteSpace(character.Persona) ? TextDb.Ui("story_event.unknown_persona") : character.Persona;
    }

    private static string GetDifficultyText(CharacterData character)
    {
        return string.IsNullOrWhiteSpace(character.Difficulty) ? TextDb.Ui("story_event.unknown_difficulty") : character.Difficulty;
    }
}
