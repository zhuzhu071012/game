using System.Collections.Generic;

namespace EraKingdomRewrite.Scripts.Data;

public static class CharacterStatCatalog
{
    private static readonly IReadOnlyDictionary<int, string> BaseNames = new Dictionary<int, string>
    {
        [0] = "体力",
        [1] = "气力",
        [2] = "射精",
        [3] = "母乳",
        [4] = "尿意",
        [5] = "毛",
        [6] = "便意"
    };

    private static readonly IReadOnlyDictionary<int, string> AbilityNames = new Dictionary<int, string>
    {
        [0] = "顺从",
        [1] = "欲望",
        [2] = "技巧",
        [3] = "C感觉",
        [4] = "V感觉",
        [5] = "A感觉",
        [6] = "B感觉",
        [7] = "侍奉精神",
        [8] = "露出癖",
        [9] = "受虐属性",
        [10] = "嗜虐属性",
        [11] = "百合属性",
        [12] = "料理技能",
        [13] = "摄影技能",
        [14] = "歌唱技能",
        [15] = "自慰成瘾",
        [16] = "精液成瘾",
        [17] = "百合成瘾",
        [18] = "性成瘾",
        [19] = "喷乳成瘾",
        [20] = "同性倾向",
        [21] = "男同成瘾",
        [22] = "W感觉",
        [23] = "T感觉",
        [24] = "E感觉"
    };

    private static readonly IReadOnlyDictionary<int, string> MarkNames = new Dictionary<int, string>
    {
        [0] = "痛苦刻印",
        [1] = "快乐刻印",
        [2] = "屈服刻印",
        [3] = "反抗刻印"
    };

    private static readonly IReadOnlyDictionary<int, string> PalamNames = new Dictionary<int, string>
    {
        [0] = "快C",
        [1] = "快V",
        [2] = "快A",
        [3] = "快B",
        [4] = "润滑",
        [5] = "恭顺",
        [6] = "情欲",
        [7] = "屈服",
        [8] = "学习",
        [9] = "耻情",
        [10] = "痛苦",
        [11] = "恐怖",
        [12] = "反感",
        [13] = "不快",
        [14] = "抑郁",
        [22] = "快W",
        [23] = "快T",
        [24] = "快E",
        [100] = "否定"
    };

    private static readonly IReadOnlyDictionary<int, string> ExperienceNames = new Dictionary<int, string>
    {
        [0] = "V经验",
        [1] = "A经验",
        [2] = "绝顶经验",
        [3] = "射精经验",
        [4] = "性交经验",
        [5] = "内射经验",
        [6] = "U经验",
        [7] = "M经验",
        [8] = "肛射经验",
        [10] = "自慰经验",
        [11] = "调教自慰经验",
        [20] = "精液经验",
        [21] = "侍奉快乐经验",
        [22] = "口交经验",
        [23] = "爱情经验",
        [24] = "精饮绝顶经验",
        [25] = "舔阴经验",
        [30] = "痛苦快乐经验",
        [31] = "放尿经验",
        [32] = "嗜虐快乐经验",
        [33] = "排便经验",
        [40] = "百合经验",
        [41] = "蔷薇经验",
        [49] = "U扩张经验",
        [50] = "异常经验",
        [51] = "紧缚经验",
        [52] = "V扩张经验",
        [53] = "A扩张经验",
        [54] = "喷乳经验",
        [55] = "触手经验",
        [56] = "吸血经验",
        [59] = "产卵经验",
        [60] = "生育经验",
        [61] = "家务经验",
        [62] = "摄影经验",
        [63] = "被拍经验",
        [64] = "歌唱经验",
        [70] = "调教经验"
    };

    public static string GetBaseName(int id)
    {
        return GetName(BaseNames, id, "基础");
    }

    public static string GetAbilityName(int id)
    {
        return GetName(AbilityNames, id, "能力");
    }

    public static string GetMarkName(int id)
    {
        return GetName(MarkNames, id, "刻印");
    }

    public static string GetPalamName(int id)
    {
        return GetName(PalamNames, id, "PALAM");
    }

    public static string GetExperienceName(int id)
    {
        return GetName(ExperienceNames, id, "经验");
    }

    private static string GetName(IReadOnlyDictionary<int, string> names, int id, string fallbackPrefix)
    {
        return names.TryGetValue(id, out var name) ? name : $"{fallbackPrefix}[{id}]";
    }
}
