using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using EraKingdomRewrite.Scripts.Core;
using EraKingdomRewrite.Scripts.Data;
using EraKingdomRewrite.Scripts.Story;
using EraKingdomRewrite.Scripts.Text;

namespace EraKingdomRewrite.Scripts.Training;

public sealed class TrainingResult
{
    public TrainingCommandDefinition Command { get; init; } = null!;
    public CharacterState CharacterState { get; init; } = null!;
    public List<string> DeltaLines { get; } = new();
    public List<string> GrowthLines { get; } = new();
    public Dictionary<int, int> AppliedPalamDelta { get; } = new();
    public Dictionary<int, int> AppliedExperienceDelta { get; } = new();
    public int AppliedRelationDelta { get; set; }
    public int AppliedDependencyDelta { get; set; }
    public int AppliedStressDelta { get; set; }
    public int AppliedMoodDelta { get; set; }

    public string BuildSummaryText()
    {
        var builder = new StringBuilder();
        if (DeltaLines.Count > 0)
        {
            builder.Append(string.Join("\n", DeltaLines));
        }

        if (GrowthLines.Count > 0)
        {
            if (builder.Length > 0)
            {
                builder.Append("\n\n");
            }

            builder.Append(string.Join("\n", GrowthLines));
        }

        return builder.Length == 0 ? TextDb.Ui("training.preview_none") : builder.ToString();
    }
}

public sealed class TrainingCalculator
{
    public TrainingResult Apply(GameState state, CharacterData character, TrainingCommandDefinition command)
    {
        var characterState = state.GetOrCreateCharacter(character.No);
        var result = Simulate(character, characterState, command);

        characterState.IsUnlocked = true;
        characterState.IsOwned = true;
        characterState.HasMet = true;
        IncrementFlag(characterState, "training.total");
        IncrementFlag(characterState, $"training.command.{command.Id}");

        ApplyClampedDelta(characterState, static value => value.RelationToPlayer, static (value, updated) => value.RelationToPlayer = updated, result.AppliedRelationDelta, result.DeltaLines, "training.result.relation");
        ApplyClampedDelta(characterState, static value => value.Dependency, static (value, updated) => value.Dependency = updated, result.AppliedDependencyDelta, result.DeltaLines, "training.result.dependency");
        ApplyClampedDelta(characterState, static value => value.Stress, static (value, updated) => value.Stress = updated, result.AppliedStressDelta, result.DeltaLines, "training.result.stress");
        ApplyClampedDelta(characterState, static value => value.Mood, static (value, updated) => value.Mood = updated, result.AppliedMoodDelta, result.DeltaLines, "training.result.mood", -999, 999);

        ApplyIndexedDelta(result.AppliedPalamDelta, characterState.Palam, CharacterStatCatalog.GetPalamName, result.DeltaLines, "training.result.stat_delta");
        ApplyIndexedDelta(result.AppliedExperienceDelta, characterState.Experience, CharacterStatCatalog.GetExperienceName, result.DeltaLines, "training.result.stat_delta");

        ApplyThresholdGrowth(characterState, result.GrowthLines);
        UpdateFallStage(characterState, result.GrowthLines);
        return result;
    }

    public TrainingResult Simulate(CharacterData character, CharacterState characterState, TrainingCommandDefinition command)
    {
        var result = new TrainingResult
        {
            Command = command,
            CharacterState = characterState
        };

        foreach (var stimulus in command.Stimuli)
        {
            var value = ComputeStimulusValue(characterState, command, stimulus);
            if (value == 0)
            {
                continue;
            }

            result.AppliedPalamDelta[stimulus.PalamId] = value;
        }

        foreach (var pair in command.ExperienceGain.OrderBy(static pair => pair.Key))
        {
            var scaled = ComputeExperienceGain(characterState, command, pair.Value);
            if (scaled == 0)
            {
                continue;
            }

            result.AppliedExperienceDelta[pair.Key] = scaled;
        }

        result.AppliedRelationDelta = ComputeRelationDelta(characterState, command, result.AppliedPalamDelta);
        result.AppliedDependencyDelta = ComputeDependencyDelta(characterState, command, result.AppliedPalamDelta);
        result.AppliedStressDelta = ComputeStressDelta(characterState, command, result.AppliedPalamDelta);
        result.AppliedMoodDelta = ComputeMoodDelta(characterState, command, result.AppliedPalamDelta, result.AppliedStressDelta);
        return result;
    }

    private static int ComputeStimulusValue(CharacterState state, TrainingCommandDefinition command, TrainingStimulusDefinition stimulus)
    {
        double value = stimulus.BaseValue;
        value *= GetToneMultiplier(command.Tone, IsNegativePalam(stimulus.PalamId));

        if (stimulus.SensitivityAbilityId >= 0)
        {
            value *= GetSensitivityMultiplier(state.GetAbility(stimulus.SensitivityAbilityId));
        }

        if (stimulus.UsesDesire)
        {
            value *= GetDesireMultiplier(state.GetAbility(1));
        }

        if (stimulus.UsesLustLevel)
        {
            value *= GetLustMultiplier(state.GetPalam(6));
        }

        if (stimulus.UsesLubrication)
        {
            value *= GetLubricationMultiplier(state.GetPalam(4));
        }

        if (stimulus.ExperienceId >= 0)
        {
            value *= GetExperienceMultiplier(state.GetExperience(stimulus.ExperienceId));
        }

        if (stimulus.PalamId == (int)StimulusType.Submission)
        {
            value *= 1.0 + (state.GetAbility(0) * 0.08);
        }

        if (stimulus.PalamId == (int)StimulusType.Pain || stimulus.PalamId == (int)StimulusType.Fear)
        {
            value *= 1.0 - Math.Min(0.35, state.GetAbility(0) * 0.03);
        }

        if (stimulus.PalamId == (int)StimulusType.Disgust && state.RelationToPlayer >= 140)
        {
            value *= 0.75;
        }

        return (int)Math.Round(value, MidpointRounding.AwayFromZero);
    }

    private static int ComputeExperienceGain(CharacterState state, TrainingCommandDefinition command, int baseGain)
    {
        var modifier = 1.0 + (state.GetAbility(2) * 0.04);
        if (command.Category == TrainingCategory.Service)
        {
            modifier += state.GetAbility(7) * 0.03;
        }

        if (command.Tone == TrainingTone.Harsh)
        {
            modifier += 0.1;
        }

        return Math.Max(1, (int)Math.Round(baseGain * modifier, MidpointRounding.AwayFromZero));
    }

    private static int ComputeRelationDelta(CharacterState state, TrainingCommandDefinition command, IReadOnlyDictionary<int, int> palamDelta)
    {
        var value = command.BaseRelationDelta;
        value += (int)Math.Round(state.GetAbility(0) * 0.3);
        value += palamDelta.GetValueOrDefault((int)StimulusType.Lust) / 10;
        value -= palamDelta.GetValueOrDefault((int)StimulusType.Fear) / 6;
        value -= palamDelta.GetValueOrDefault((int)StimulusType.Disgust) / 5;
        if (command.Tone == TrainingTone.Gentle && state.Stress <= 30)
        {
            value += 2;
        }
        return value;
    }

    private static int ComputeDependencyDelta(CharacterState state, TrainingCommandDefinition command, IReadOnlyDictionary<int, int> palamDelta)
    {
        var value = command.BaseDependencyDelta;
        value += palamDelta.GetValueOrDefault((int)StimulusType.Submission) / 10;
        value += palamDelta.GetValueOrDefault((int)StimulusType.Lust) / 12;
        value += state.GetAbility(0) / 2;
        if (command.Category == TrainingCategory.Service)
        {
            value += 2;
        }
        return value;
    }

    private static int ComputeStressDelta(CharacterState state, TrainingCommandDefinition command, IReadOnlyDictionary<int, int> palamDelta)
    {
        var value = command.BaseStressDelta;
        value += palamDelta.GetValueOrDefault((int)StimulusType.Pain) / 6;
        value += palamDelta.GetValueOrDefault((int)StimulusType.Fear) / 8;
        value += palamDelta.GetValueOrDefault((int)StimulusType.Disgust) / 10;
        value -= Math.Min(6, state.GetAbility(0) / 2);
        if (command.Tone == TrainingTone.Gentle)
        {
            value -= 2;
        }
        return value;
    }

    private static int ComputeMoodDelta(CharacterState state, TrainingCommandDefinition command, IReadOnlyDictionary<int, int> palamDelta, int stressDelta)
    {
        var value = command.BaseMoodDelta;
        value += palamDelta.GetValueOrDefault((int)StimulusType.Lust) / 12;
        value += palamDelta.GetValueOrDefault((int)StimulusType.PleasureC) / 16;
        value += palamDelta.GetValueOrDefault((int)StimulusType.PleasureB) / 16;
        value -= palamDelta.GetValueOrDefault((int)StimulusType.Disgust) / 6;
        value -= palamDelta.GetValueOrDefault((int)StimulusType.Depression) / 8;
        value -= Math.Max(0, stressDelta) / 3;
        if (command.Tone == TrainingTone.Harsh)
        {
            value -= 2;
        }
        if (state.RelationToPlayer >= 150 && command.Tone == TrainingTone.Gentle)
        {
            value += 2;
        }
        return value;
    }

    private static void IncrementFlag(CharacterState characterState, string key)
    {
        characterState.LocalFlags.TryGetValue(key, out var value);
        characterState.LocalFlags[key] = value + 1;
    }

    private static void ApplyClampedDelta(
        CharacterState characterState,
        Func<CharacterState, int> getter,
        Action<CharacterState, int> setter,
        int delta,
        ICollection<string> output,
        string key,
        int min = 0,
        int max = 999)
    {
        if (delta == 0)
        {
            return;
        }

        setter(characterState, Math.Clamp(getter(characterState) + delta, min, max));
        output.Add(TextDb.UiFormat(key, FormatSigned(delta)));
    }

    private static void ApplyIndexedDelta(
        IReadOnlyDictionary<int, int> deltas,
        IDictionary<int, int> values,
        Func<int, string> nameResolver,
        ICollection<string> output,
        string formatKey)
    {
        foreach (var pair in deltas.OrderBy(static pair => pair.Key))
        {
            if (pair.Value == 0)
            {
                continue;
            }

            values.TryGetValue(pair.Key, out var current);
            values[pair.Key] = Math.Max(0, current + pair.Value);
            output.Add(TextDb.UiFormat(formatKey, nameResolver(pair.Key), FormatSigned(pair.Value)));
        }
    }

    private static void ApplyThresholdGrowth(CharacterState characterState, ICollection<string> output)
    {
        ResolveAbilityGrowth(characterState, 0, 3, 80, output);
        ResolveAbilityGrowth(characterState, 1, 4, 80, output);
        ResolveAbilityGrowth(characterState, 2, 5, 80, output);
        ResolveAbilityGrowth(characterState, 3, 6, 80, output);
        ResolveAbilityGrowth(characterState, 6, 1, 90, output);
        ResolveAbilityGrowth(characterState, 7, 0, 90, output);
        ResolveAbilityGrowth(characterState, 8, 2, 70, output);
        ResolveMarkGrowth(characterState, 10, 0, 90, output);
        ResolveMarkGrowth(characterState, 0, 1, 120, output);
        ResolveMarkGrowth(characterState, 7, 2, 120, output);
        ResolveMarkGrowth(characterState, 12, 3, 120, output);
    }

    private static void ResolveAbilityGrowth(CharacterState characterState, int palamId, int abilityId, int threshold, ICollection<string> output)
    {
        while (characterState.GetPalam(palamId) >= threshold)
        {
            characterState.Palam[palamId] -= threshold;
            characterState.Abilities.TryGetValue(abilityId, out var current);
            var updated = Math.Min(10, current + 1);
            if (updated == current)
            {
                break;
            }

            characterState.Abilities[abilityId] = updated;
            output.Add(TextDb.UiFormat("training.result.ability_growth", CharacterStatCatalog.GetAbilityName(abilityId), updated));
        }
    }

    private static void ResolveMarkGrowth(CharacterState characterState, int palamId, int markId, int threshold, ICollection<string> output)
    {
        while (characterState.GetPalam(palamId) >= threshold)
        {
            characterState.Palam[palamId] -= threshold;
            characterState.Marks.TryGetValue(markId, out var current);
            var updated = Math.Min(3, current + 1);
            if (updated == current)
            {
                break;
            }

            characterState.Marks[markId] = updated;
            output.Add(TextDb.UiFormat("training.result.mark_growth", CharacterStatCatalog.GetMarkName(markId), updated));
        }
    }

    private static void UpdateFallStage(CharacterState characterState, ICollection<string> output)
    {
        var nextStage = characterState.CurrentFallStage;
        if (characterState.GetPalam(6) >= 110 || characterState.GetAbility(1) >= 2)
        {
            nextStage = MaxStage(nextStage, FallStage.Lust);
        }

        if (characterState.RelationToPlayer >= 150 && characterState.Dependency >= 50 && characterState.Stress <= 60)
        {
            nextStage = MaxStage(nextStage, FallStage.Love);
        }

        if (characterState.GetPalam(7) >= 130 || characterState.GetMark(2) >= 2)
        {
            nextStage = MaxStage(nextStage, FallStage.Obedience);
        }

        if (characterState.RelationToPlayer >= 220 && characterState.Dependency >= 120)
        {
            nextStage = MaxStage(nextStage, FallStage.DeepLove);
        }

        if (characterState.GetMark(2) >= 3 && characterState.Dependency >= 150)
        {
            nextStage = MaxStage(nextStage, FallStage.Slave);
        }

        if (nextStage != characterState.CurrentFallStage)
        {
            characterState.ReachStage(nextStage);
            output.Add(TextDb.UiFormat("training.result.stage_growth", GetFallStageText(nextStage)));
        }
    }

    private static FallStage MaxStage(FallStage left, FallStage right)
    {
        return left >= right ? left : right;
    }

    private static double GetSensitivityMultiplier(int abilityLevel)
    {
        return abilityLevel switch
        {
            <= 0 => 0.8,
            1 => 1.2,
            2 => 1.6,
            3 => 2.1,
            4 => 2.7,
            5 => 3.3,
            _ => 3.3 + ((abilityLevel - 5) * 0.35)
        };
    }

    private static double GetDesireMultiplier(int desireLevel)
    {
        return desireLevel switch
        {
            <= 0 => 0.5,
            1 => 0.7,
            2 => 0.85,
            3 => 1.0,
            4 => 1.1,
            5 => 1.2,
            _ => 1.2 + ((desireLevel - 5) * 0.05)
        };
    }

    private static double GetLustMultiplier(int lustPalam)
    {
        return lustPalam switch
        {
            < 30 => 0.7,
            < 60 => 0.9,
            < 100 => 1.1,
            < 150 => 1.35,
            _ => 1.6
        };
    }

    private static double GetLubricationMultiplier(int lubricationPalam)
    {
        return lubricationPalam switch
        {
            < 20 => 0.3,
            < 50 => 0.7,
            < 90 => 1.0,
            < 140 => 1.3,
            _ => 1.6
        };
    }

    private static double GetExperienceMultiplier(int experienceValue)
    {
        return experienceValue switch
        {
            < 5 => 0.7,
            < 15 => 0.9,
            < 30 => 1.0,
            < 60 => 1.2,
            _ => 1.4
        };
    }

    private static double GetToneMultiplier(TrainingTone tone, bool negativePalam)
    {
        return tone switch
        {
            TrainingTone.Gentle when negativePalam => 0.65,
            TrainingTone.Gentle => 1.05,
            TrainingTone.Harsh when negativePalam => 1.2,
            TrainingTone.Harsh => 0.92,
            _ => 1.0
        };
    }

    private static bool IsNegativePalam(int palamId)
    {
        return palamId is 10 or 11 or 12 or 14;
    }

    private static string GetFallStageText(FallStage stage)
    {
        return stage switch
        {
            FallStage.Love => TextDb.Ui("fall_stage.love"),
            FallStage.Obedience => TextDb.Ui("fall_stage.obedience"),
            FallStage.Lust => TextDb.Ui("fall_stage.lust"),
            FallStage.DeepLove => TextDb.Ui("fall_stage.deep_love"),
            FallStage.Slave => TextDb.Ui("fall_stage.slave"),
            FallStage.Consort => TextDb.Ui("fall_stage.consort"),
            _ => TextDb.Ui("fall_stage.none")
        };
    }

    private static string FormatSigned(int value)
    {
        return value >= 0 ? $"+{value}" : value.ToString();
    }
}

public sealed class TrainingDialogueFactory
{
    public IReadOnlyList<StoryLine> BuildLines(CharacterData character, CharacterState characterState, TrainingResult result)
    {
        var commandName = TextDb.Ui(result.Command.NameKey);
        var profileHook = BuildProfileHook(character);
        return new List<StoryLine>
        {
            new()
            {
                Speaker = TextDb.Ui("story_event.narrator"),
                Text = TextDb.UiFormat(GetIntroKey(result.Command.Tone), character.Name, commandName)
            },
            new()
            {
                Speaker = character.Name,
                Text = TextDb.UiFormat(GetResponseKey(result.Command.Tone, characterState), profileHook, character.GetSubjectPronoun(), commandName)
            },
            new()
            {
                Speaker = TextDb.Ui("story_event.narrator"),
                Text = TextDb.UiFormat("training.story.result_line", result.BuildSummaryText())
            }
        };
    }

    private static string BuildProfileHook(CharacterData character)
    {
        var line = Enumerable.Range(92, 7)
            .Select(character.GetProfileLine)
            .FirstOrDefault(static value => !string.IsNullOrWhiteSpace(value));
        return string.IsNullOrWhiteSpace(line)
            ? TextDb.UiFormat("story_event.profile_fallback", character.Faction, character.Job, character.Persona)
            : line;
    }

    private static string GetIntroKey(TrainingTone tone)
    {
        return tone switch
        {
            TrainingTone.Harsh => "training.story.harsh_intro",
            TrainingTone.Neutral => "training.story.neutral_intro",
            _ => "training.story.gentle_intro"
        };
    }

    private static string GetResponseKey(TrainingTone tone, CharacterState characterState)
    {
        if (tone == TrainingTone.Harsh)
        {
            return characterState.Stress >= 60 || characterState.RelationToPlayer <= 60
                ? "training.story.response_resist"
                : "training.story.response_endure";
        }

        return characterState.RelationToPlayer >= 140 || characterState.Mood >= 50
            ? "training.story.response_soft"
            : "training.story.response_guarded";
    }
}
