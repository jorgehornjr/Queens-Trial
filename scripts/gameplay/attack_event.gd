class_name AttackEvent
extends Node

## Emitido sempre que um par de peças termina de atacar e o resultado
## precisa ser avaliado (casas atingidas, acerto no jogador, safe spot).
signal resolved(result: Dictionary)


func resolve(attacked_cells: Array[Vector2i], player_cell: Vector2i, safe_spot: Vector2i) -> Dictionary:
	var player_hit := attacked_cells.has(player_cell)
	var reached_safe_spot := player_cell == safe_spot

	var result := {
		"attacked_cells": attacked_cells,
		"player_hit": player_hit,
		"reached_safe_spot": reached_safe_spot,
		"success": reached_safe_spot and not player_hit,
	}

	resolved.emit(result)
	return result
