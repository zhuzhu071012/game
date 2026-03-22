using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;

namespace EraKingdomRewrite.Scripts.Training;

public enum TrainingTone
{
    Gentle = 0,
    Neutral = 1,
    Harsh = 2
}

public enum TrainingCategory
{
    Affection = 0,
    Daily = 1,
    Service = 2,
    Sm = 3
}

public enum StimulusType
{
    PleasureC = 0,
    PleasureV = 1,
    PleasureA = 2,
    PleasureB = 3,
    Lubrication = 4,
    Submission = 5,
    Lust = 6,
    Shame = 9,
    Pain = 10,
    Fear = 11,
    Disgust = 12,
    Depression = 14
}

public sealed class TrainingStimulusDefinition
{
    public int PalamId { get; init; }
    public int BaseValue { get; init; }
    public int SensitivityAbilityId { get; init; } = -1;
    public int ExperienceId { get; init; } = -1;
    public bool UsesLubrication { get; init; }
    public bool UsesDesire { get; init; } = true;
    public bool UsesLustLevel { get; init; } = true;
}

public sealed class TrainingCommandDefinition
{
    public string Id { get; init; } = string.Empty;
    public int LegacyId { get; init; }
    public string NameKey { get; init; } = string.Empty;
    public string DescriptionKey { get; init; } = string.Empty;
    public string CategoryKey { get; init; } = string.Empty;
    public TrainingCategory Category { get; init; }
    public TrainingTone Tone { get; init; }
    public int BaseRelationDelta { get; init; }
    public int BaseDependencyDelta { get; init; }
    public int BaseStressDelta { get; init; }
    public int BaseMoodDelta { get; init; }
    public IReadOnlyList<TrainingStimulusDefinition> Stimuli { get; init; } = Array.Empty<TrainingStimulusDefinition>();
    public IReadOnlyDictionary<int, int> ExperienceGain { get; init; } = new ReadOnlyDictionary<int, int>(new Dictionary<int, int>());
}

public static class TrainingCommandCatalog
{
    private static readonly IReadOnlyList<TrainingCommandDefinition> Definitions = new[]
    {
        Create(
            "caress",
            0,
            "training.command.caress.name",
            "training.command.caress.desc",
            TrainingCategory.Affection,
            "training.category.affection",
            TrainingTone.Gentle,
            baseRelationDelta: 3,
            baseDependencyDelta: 2,
            baseStressDelta: -1,
            baseMoodDelta: 5,
            stimuli: new[]
            {
                Stimulus(0, 8, sensitivityAbilityId: 3),
                Stimulus(4, 4, usesDesire: false, usesLustLevel: false),
                Stimulus(6, 6)
            },
            experienceGain: new Dictionary<int, int> { [10] = 1, [70] = 1 }),
        Create(
            "kiss",
            20,
            "training.command.kiss.name",
            "training.command.kiss.desc",
            TrainingCategory.Affection,
            "training.category.affection",
            TrainingTone.Gentle,
            baseRelationDelta: 5,
            baseDependencyDelta: 3,
            baseStressDelta: -2,
            baseMoodDelta: 7,
            stimuli: new[]
            {
                Stimulus(6, 10),
                Stimulus(9, 4, usesDesire: false)
            },
            experienceGain: new Dictionary<int, int> { [23] = 1, [70] = 1 }),
        Create(
            "talk",
            22,
            "training.command.talk.name",
            "training.command.talk.desc",
            TrainingCategory.Daily,
            "training.category.daily",
            TrainingTone.Neutral,
            baseRelationDelta: 4,
            baseDependencyDelta: 1,
            baseStressDelta: -5,
            baseMoodDelta: 4,
            stimuli: new[]
            {
                Stimulus(8, 6, usesDesire: false, usesLustLevel: false),
                Stimulus(9, -2, usesDesire: false, usesLustLevel: false)
            },
            experienceGain: new Dictionary<int, int> { [61] = 1 }),
        Create(
            "gift",
            23,
            "training.command.gift.name",
            "training.command.gift.desc",
            TrainingCategory.Daily,
            "training.category.daily",
            TrainingTone.Gentle,
            baseRelationDelta: 8,
            baseDependencyDelta: 1,
            baseStressDelta: -3,
            baseMoodDelta: 8,
            stimuli: new[]
            {
                Stimulus(6, 4),
                Stimulus(9, 2, usesDesire: false)
            },
            experienceGain: new Dictionary<int, int>()),
        Create(
            "touch",
            24,
            "training.command.touch.name",
            "training.command.touch.desc",
            TrainingCategory.Affection,
            "training.category.affection",
            TrainingTone.Gentle,
            baseRelationDelta: 3,
            baseDependencyDelta: 4,
            baseStressDelta: 0,
            baseMoodDelta: 4,
            stimuli: new[]
            {
                Stimulus(4, 8, usesDesire: false, usesLustLevel: false),
                Stimulus(6, 12),
                Stimulus(9, 4, usesDesire: false)
            },
            experienceGain: new Dictionary<int, int> { [70] = 1 }),
        Create(
            "blowjob",
            2,
            "training.command.blowjob.name",
            "training.command.blowjob.desc",
            TrainingCategory.Service,
            "training.category.service",
            TrainingTone.Neutral,
            baseRelationDelta: 1,
            baseDependencyDelta: 5,
            baseStressDelta: 2,
            baseMoodDelta: 1,
            stimuli: new[]
            {
                Stimulus(6, 10),
                Stimulus(9, 6, usesDesire: false),
                Stimulus(12, 2, usesDesire: false, usesLustLevel: false)
            },
            experienceGain: new Dictionary<int, int> { [22] = 2, [20] = 1, [70] = 1 }),
        Create(
            "nipple_play",
            7,
            "training.command.nipple_play.name",
            "training.command.nipple_play.desc",
            TrainingCategory.Affection,
            "training.category.affection",
            TrainingTone.Gentle,
            baseRelationDelta: 1,
            baseDependencyDelta: 2,
            baseStressDelta: 0,
            baseMoodDelta: 2,
            stimuli: new[]
            {
                Stimulus(3, 8, sensitivityAbilityId: 6),
                Stimulus(6, 6)
            },
            experienceGain: new Dictionary<int, int> { [70] = 1 }),
        Create(
            "service_hand",
            80,
            "training.command.service_hand.name",
            "training.command.service_hand.desc",
            TrainingCategory.Service,
            "training.category.service",
            TrainingTone.Neutral,
            baseRelationDelta: 0,
            baseDependencyDelta: 5,
            baseStressDelta: 1,
            baseMoodDelta: 1,
            stimuli: new[]
            {
                Stimulus(6, 8),
                Stimulus(9, 4, usesDesire: false)
            },
            experienceGain: new Dictionary<int, int> { [3] = 1, [20] = 1, [70] = 1 }),
        Create(
            "service_feet",
            86,
            "training.command.service_feet.name",
            "training.command.service_feet.desc",
            TrainingCategory.Service,
            "training.category.service",
            TrainingTone.Neutral,
            baseRelationDelta: -1,
            baseDependencyDelta: 4,
            baseStressDelta: 3,
            baseMoodDelta: -1,
            stimuli: new[]
            {
                Stimulus(7, 8, usesDesire: false),
                Stimulus(9, 5, usesDesire: false),
                Stimulus(12, 3, usesDesire: false, usesLustLevel: false)
            },
            experienceGain: new Dictionary<int, int> { [21] = 1, [70] = 1 }),
        Create(
            "spanking",
            100,
            "training.command.spanking.name",
            "training.command.spanking.desc",
            TrainingCategory.Sm,
            "training.category.sm",
            TrainingTone.Harsh,
            baseRelationDelta: -5,
            baseDependencyDelta: 3,
            baseStressDelta: 9,
            baseMoodDelta: -5,
            stimuli: new[]
            {
                Stimulus(10, 12, usesDesire: false, usesLustLevel: false),
                Stimulus(11, 6, usesDesire: false, usesLustLevel: false),
                Stimulus(7, 6, usesDesire: false)
            },
            experienceGain: new Dictionary<int, int> { [30] = 1, [70] = 1 }),
        Create(
            "whip",
            102,
            "training.command.whip.name",
            "training.command.whip.desc",
            TrainingCategory.Sm,
            "training.category.sm",
            TrainingTone.Harsh,
            baseRelationDelta: -8,
            baseDependencyDelta: 4,
            baseStressDelta: 14,
            baseMoodDelta: -8,
            stimuli: new[]
            {
                Stimulus(10, 18, usesDesire: false, usesLustLevel: false),
                Stimulus(11, 10, usesDesire: false, usesLustLevel: false),
                Stimulus(12, 6, usesDesire: false, usesLustLevel: false),
                Stimulus(7, 8, usesDesire: false)
            },
            experienceGain: new Dictionary<int, int> { [30] = 2, [70] = 1 }),
        Create(
            "bondage",
            106,
            "training.command.bondage.name",
            "training.command.bondage.desc",
            TrainingCategory.Sm,
            "training.category.sm",
            TrainingTone.Harsh,
            baseRelationDelta: -3,
            baseDependencyDelta: 6,
            baseStressDelta: 8,
            baseMoodDelta: -4,
            stimuli: new[]
            {
                Stimulus(11, 8, usesDesire: false, usesLustLevel: false),
                Stimulus(7, 10, usesDesire: false),
                Stimulus(9, 5, usesDesire: false)
            },
            experienceGain: new Dictionary<int, int> { [51] = 2, [70] = 1 }),
        Create(
            "interrogation",
            108,
            "training.command.interrogation.name",
            "training.command.interrogation.desc",
            TrainingCategory.Sm,
            "training.category.sm",
            TrainingTone.Harsh,
            baseRelationDelta: -6,
            baseDependencyDelta: 4,
            baseStressDelta: 12,
            baseMoodDelta: -7,
            stimuli: new[]
            {
                Stimulus(11, 12, usesDesire: false, usesLustLevel: false),
                Stimulus(12, 10, usesDesire: false, usesLustLevel: false),
                Stimulus(14, 8, usesDesire: false, usesLustLevel: false)
            },
            experienceGain: new Dictionary<int, int> { [70] = 2 }),
        Create(
            "violence",
            30,
            "training.command.violence.name",
            "training.command.violence.desc",
            TrainingCategory.Sm,
            "training.category.sm",
            TrainingTone.Harsh,
            baseRelationDelta: -10,
            baseDependencyDelta: 3,
            baseStressDelta: 16,
            baseMoodDelta: -10,
            stimuli: new[]
            {
                Stimulus(10, 20, usesDesire: false, usesLustLevel: false),
                Stimulus(11, 14, usesDesire: false, usesLustLevel: false),
                Stimulus(12, 10, usesDesire: false, usesLustLevel: false),
                Stimulus(14, 8, usesDesire: false, usesLustLevel: false)
            },
            experienceGain: new Dictionary<int, int> { [30] = 2, [70] = 1 })
    };

    public static IReadOnlyList<TrainingCommandDefinition> All => Definitions;

    public static TrainingCommandDefinition GetRequired(string id)
    {
        foreach (var definition in Definitions)
        {
            if (string.Equals(definition.Id, id, StringComparison.Ordinal))
            {
                return definition;
            }
        }

        throw new InvalidOperationException($"Unknown training command: {id}");
    }

    private static TrainingCommandDefinition Create(
        string id,
        int legacyId,
        string nameKey,
        string descriptionKey,
        TrainingCategory category,
        string categoryKey,
        TrainingTone tone,
        int baseRelationDelta,
        int baseDependencyDelta,
        int baseStressDelta,
        int baseMoodDelta,
        IReadOnlyList<TrainingStimulusDefinition> stimuli,
        Dictionary<int, int> experienceGain)
    {
        return new TrainingCommandDefinition
        {
            Id = id,
            LegacyId = legacyId,
            NameKey = nameKey,
            DescriptionKey = descriptionKey,
            Category = category,
            CategoryKey = categoryKey,
            Tone = tone,
            BaseRelationDelta = baseRelationDelta,
            BaseDependencyDelta = baseDependencyDelta,
            BaseStressDelta = baseStressDelta,
            BaseMoodDelta = baseMoodDelta,
            Stimuli = stimuli,
            ExperienceGain = new ReadOnlyDictionary<int, int>(experienceGain)
        };
    }

    private static TrainingStimulusDefinition Stimulus(
        int palamId,
        int baseValue,
        int sensitivityAbilityId = -1,
        int experienceId = -1,
        bool usesLubrication = false,
        bool usesDesire = true,
        bool usesLustLevel = true)
    {
        return new TrainingStimulusDefinition
        {
            PalamId = palamId,
            BaseValue = baseValue,
            SensitivityAbilityId = sensitivityAbilityId,
            ExperienceId = experienceId,
            UsesLubrication = usesLubrication,
            UsesDesire = usesDesire,
            UsesLustLevel = usesLustLevel
        };
    }
}
