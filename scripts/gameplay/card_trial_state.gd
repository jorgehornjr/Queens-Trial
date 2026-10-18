class_name CardTrialState
extends RefCounted

enum Kind { ORDER, MATCH, FALSE_DECREE }
var phase_number := 7
var round_index := 0
var kind := Kind.ORDER
var ascending := true
var anchor_index := -1
var anchor_value := 0
var slots: Array[int] = []
var targets: Array[int] = []
var deck: Array[int] = []
var options: Array[int] = []
var claims: Array[int] = []
var false_index := -1
var solved := false
var _seed := 1

func begin(number: int, seed_value: int) -> void:
	phase_number = number
	_seed = seed_value
	round_index = 0
	prepare_round()

func prepare_round() -> void:
	solved = false
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed + round_index * 919
	deck.clear()
	for n in range(1, 21): deck.append(n)
	_shuffle(deck, rng)
	var ordered := _ordered_deck()
	var reversed := ordered.duplicate()
	reversed.reverse()
	if deck == ordered or deck == reversed:
		var first := deck[0]
		deck[0] = deck[7]
		deck[7] = first
	anchor_index = -1
	anchor_value = 0
	options.clear()
	claims.clear()
	if phase_number == 7:
		kind = Kind.ORDER
		ascending = round_index == 0
		var sample: Array[int] = []
		for i in range(6): sample.append(deck[i])
		sample.sort()
		if not ascending: sample.reverse()
		anchor_index = rng.randi_range(1, 4)
		anchor_value = sample[anchor_index]
		slots.assign([0, 0, 0, 0, 0, 0])
		slots[anchor_index] = anchor_value
		targets.clear()
	elif round_index == 0:
		kind = Kind.MATCH
		targets.assign([14, 18, 19])
		slots.assign([0, 0, 0])
	else:
		kind = Kind.FALSE_DECREE
		options.assign([9, 14, 19])
		_shuffle(options, rng)
		claims.assign(options)
		false_index = rng.randi_range(0, 2)
		var confusions := {9: 11, 14: 16, 19: 18}
		claims[false_index] = confusions[options[false_index]]
		slots.clear()
		targets.clear()

func place(slot: int, value: int) -> bool:
	if solved or kind == Kind.FALSE_DECREE or slot < 0 or slot >= slots.size() or slot == anchor_index or value not in range(1, 21) or value == anchor_value: return false
	var source := slots.find(value)
	var previous := slots[slot]
	if source >= 0: slots[source] = previous
	slots[slot] = value
	return true

func remove(slot: int) -> bool:
	if solved or slot < 0 or slot >= slots.size() or slot == anchor_index: return false
	slots[slot] = 0
	return true

func check() -> Dictionary:
	if kind == Kind.FALSE_DECREE: return {"correct": false, "message": "Selecione a correspondência falsa."}
	if slots.has(0): return {"correct": false, "message": "Preencha todos os espaços antes de confirmar."}
	if kind == Kind.MATCH:
		for i in range(slots.size()):
			if slots[i] != targets[i]:
				return {"correct": false, "message": "%s representa %d. Este espaço pede %d." % [GameConstants.to_roman(slots[i]), slots[i], targets[i]]}
	elif kind == Kind.ORDER:
		for i in range(1, slots.size()):
			if (ascending and slots[i - 1] >= slots[i]) or (not ascending and slots[i - 1] <= slots[i]):
				var rule := "Na ordem crescente, o menor número vem primeiro." if ascending else "Na ordem decrescente, o maior número vem primeiro."
				return {"correct": false, "message": "%s vale %d e %s vale %d.\n%s" % [GameConstants.to_roman(slots[i - 1]), slots[i - 1], GameConstants.to_roman(slots[i]), slots[i], rule]}
	solved = true
	return {"correct": true, "message": "Correspondências corretas." if kind == Kind.MATCH else "Sequência correta."}

func choose_false(index: int) -> Dictionary:
	if solved or index < 0 or index >= options.size(): return {"correct": false, "message": ""}
	if index != false_index:
		return {"correct": false, "message": "Esta correspondência está correta: %s = %d.\nVocê precisa encontrar a carta que mostra um valor diferente do número acima dela." % [GameConstants.to_roman(options[index]), claims[index]]}
	solved = true
	return {"correct": true, "message": "Decreto falso: %s representa %d, e não %d." % [GameConstants.to_roman(options[index]), options[index], claims[index]]}

func next_round() -> bool:
	if not solved or round_index >= 1: return false
	round_index += 1
	prepare_round()
	return true

func _ordered_deck() -> Array[int]:
	var ordered: Array[int] = []
	for n in range(1, 21): ordered.append(n)
	return ordered

static func _shuffle(values: Array[int], rng: RandomNumberGenerator) -> void:
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var value := values[i]
		values[i] = values[j]
		values[j] = value
