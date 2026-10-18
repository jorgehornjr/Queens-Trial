class_name CampaignProgress
extends RefCounted
## Completion, rather than visiting a phase, unlocks Savage.
const PATH := "user://campaign_progress.cfg"

static func completed_phases(path: String = PATH) -> Array[int]:
	var result: Array[int] = []
	var config := ConfigFile.new()
	if config.load(path) != OK: return result
	for value in config.get_value("campaign", "completed", []):
		if int(value) in range(1, PhaseManager.LAST_PLAYABLE_PHASE + 1) and int(value) not in result:
			result.append(int(value))
	return result

static func record_completion(number: int, path: String = PATH) -> void:
	if number not in range(1, PhaseManager.LAST_PLAYABLE_PHASE + 1): return
	var cleared := completed_phases(path)
	if number not in cleared: cleared.append(number)
	var config := ConfigFile.new()
	config.set_value("campaign", "completed", cleared)
	var error := config.save(path)
	if error != OK: push_warning("Não foi possível salvar o progresso: %s" % error_string(error))

static func savage_unlocked(path: String = PATH) -> bool:
	return completed_phases(path).size() == PhaseManager.LAST_PLAYABLE_PHASE
