class_name GameConstants
extends RefCounted

const BOARD_SIZE := 5
const QUEEN_CELL := Vector2i(2, 2)

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
}


static func to_roman(value: int) -> String:
	return String(ROMAN_BY_VALUE.get(value, ""))
