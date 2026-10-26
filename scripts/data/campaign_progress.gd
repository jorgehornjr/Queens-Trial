class_name CampaignProgress
extends RefCounted
# O progresso dura apenas nesta execução do jogo.
const PATH := "user://campaign_progress.cfg"
static var _completed: Array[int] = []

static func completed_phases(_path: String = PATH) -> Array[int]:
	return _completed.duplicate()

static func record_completion(number: int, _path: String = PATH) -> void:
	if number not in range(1, PhaseManager.LAST_PLAYABLE_PHASE + 1): return
	if number not in _completed: _completed.append(number)

static func savage_unlocked(path: String = PATH) -> bool:

	return PhaseManager.LAST_PLAYABLE_PHASE in completed_phases(path)

static func reset() -> void:
	_completed.clear()
