# Data Layout

`data/texts/`
放所有中文文案。人物姓名、简介、事件标题、日志文本都继续从这里读取，后续补文本时优先修改这里。

`data/definitions/`
放可调的静态数值定义。人物属性、专长、标签、被动与卡面资源放这里，后续平衡优先改这里。

## Character Definitions

当前人物定义文件：

- `characters.json`

人物定义里不直接写人物姓名和正文文案，运行时仍通过 `TextDB` 读取 `data/texts/*.json`，这样可以把“数值调整”和“文本补写”分开。

## Specialty Mapping

中文专长和内部 id 的对应关系如下：

- 威慑 -> `intimidation`
- 交涉 -> `negotiation`
- 治军 -> `command`
- 奇谋 -> `stratagem`
- 搜索 -> `search`
- 欺诈 -> `deception`
- 医疗 -> `medical`
