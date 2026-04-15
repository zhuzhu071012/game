extends RefCounted
class_name UiPalette

const SLATE := Color8(62, 69, 68)
const SAGE := Color8(90, 119, 96)
const RUST := Color8(130, 50, 40)
const VERMILION := Color8(180, 80, 70)
const PAPER := Color8(255, 255, 255)
const INK := Color8(51, 51, 51)

static func alpha(color: Color, value: float) -> Color:
	var tinted := color
	tinted.a = clampf(value, 0.0, 1.0)
	return tinted
