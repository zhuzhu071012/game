using EraKingdomRewrite.Scripts.Core;
namespace EraKingdomRewrite.Scripts.Systems;
public sealed class FallConditionService
{
    public FallStage? EvaluateBasicFall(CharacterState character)
    {
        if (CanReachLove(character))
        {
            return FallStage.Love;
        }
        if (CanReachObedience(character))
        {
            return FallStage.Obedience;
        }
        if (CanReachLust(character))
        {
            return FallStage.Lust;
        }
        return null;
    }
    public bool TryApplyBasicFall(CharacterState character, out FallStage reachedStage)
    {
        reachedStage = FallStage.None;
        var nextStage = EvaluateBasicFall(character);
        if (!nextStage.HasValue || character.HasReached(nextStage.Value))
        {
            return false;
        }
        character.ReachStage(nextStage.Value);
        reachedStage = nextStage.Value;
        return true;
    }
    private static bool CanReachLove(CharacterState character)
    {
        return character.GetAbility(0) >= 3
            && character.GetAbility(7) >= 3
            && character.GetMark(2) >= 3
            && character.GetMark(3) == 0
            && character.GetExperience(21) >= 200
            && character.Dependency >= 1000
            && character.GetExperience(50) < 2;
    }
    private static bool CanReachObedience(CharacterState character)
    {
        return character.GetAbility(0) >= 3
            && character.GetAbility(9) >= 3
            && character.GetAbility(3) + character.GetAbility(4) + character.GetAbility(5) + character.GetAbility(6) < 10
            && character.GetMark(2) >= 3
            && character.GetMark(3) == 0
            && character.GetExperience(30) + character.GetExperience(51) >= 200
            && character.Dependency <= -1000
            && character.GetExperience(50) >= 2;
    }
    private static bool CanReachLust(CharacterState character)
    {
        return character.GetAbility(1) >= 3
            && character.GetAbility(3) + character.GetAbility(4) + character.GetAbility(5) + character.GetAbility(6) >= 10
            && character.GetMark(1) >= 3
            && character.GetMark(2) >= 3
            && character.GetMark(3) == 0
            && character.GetExperience(2) >= 50
            && character.GetExperience(50) >= 3;
    }
}
