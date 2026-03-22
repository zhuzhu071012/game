using System.Collections.Generic;
using System.Linq;
using EraKingdomRewrite.Scripts.Data;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.Story;

public sealed class PurchaseEventFactory
{
    public StoryEvent Create(CharacterData character)
    {
        var storyId = $"purchase.{character.No}";
        return new StoryEvent
        {
            Id = storyId,
            Title = TextDb.UiFormat("story_event.purchase_title", character.Name),
            TriggerOnce = true,
            Priority = 200,
            Condition = new StoryCondition
            {
                CharacterId = character.No
            },
            Lines = BuildLines(character),
            Actions = new List<StoryAction>
            {
                new()
                {
                    Type = StoryActionType.AddMoney,
                    IntValue = -character.Price
                },
                new()
                {
                    Type = StoryActionType.OwnCharacter,
                    IntValue = character.No
                },
                new()
                {
                    Type = StoryActionType.SetCurrentTargetCharacter,
                    IntValue = character.No
                },
                new()
                {
                    Type = StoryActionType.CompleteStory,
                    StringValue = storyId
                }
            }
        };
    }

    private static List<StoryLine> BuildLines(CharacterData character)
    {
        var pronoun = character.GetSubjectPronoun();
        return new List<StoryLine>
        {
            new()
            {
                Speaker = TextDb.Ui("story_event.narrator"),
                Text = TextDb.UiFormat(
                    "story_event.purchase_line_1",
                    character.Name,
                    character.Price,
                    GetFactionText(character),
                    GetJobText(character))
            },
            new()
            {
                Speaker = character.Name,
                Text = BuildProfileHook(character)
            },
            new()
            {
                Speaker = TextDb.Ui("story_event.narrator"),
                Text = TextDb.UiFormat(
                    "story_event.purchase_line_3",
                    character.Name,
                    pronoun,
                    GetPersonaText(character))
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
            return TextDb.UiFormat("story_event.purchase_line_2", profileLine);
        }

        return TextDb.UiFormat(
            "story_event.purchase_line_2",
            TextDb.UiFormat("story_event.profile_fallback", GetFactionText(character), GetJobText(character), GetPersonaText(character)));
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
}
