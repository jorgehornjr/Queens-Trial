class_name GameConstants
extends RefCounted

const BOARD_SIZE := 5

const PIECE_ROOK: StringName = &"rook"
const PIECE_BISHOP: StringName = &"bishop"

const ROMAN_BY_VALUE := {
	1: "I",
	2: "II",
	3: "III",
	4: "IV",
	5: "V",
	6: "VI",
	7: "VII",
	8: "VIII", 9: "IX", 10: "X", 11: "XI", 12: "XII", 13: "XIII",
	14: "XIV", 15: "XV", 16: "XVI", 17: "XVII", 18: "XVIII", 19: "XIX", 20: "XX",
}


static func to_roman(value: int) -> String:
	return String(ROMAN_BY_VALUE.get(value, ""))
