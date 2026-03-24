extends Node
class_name RelationManager

signal relation_changed(character_id: String)

func apply_favor(run_state: RunState, character_id: String, delta: int) -> void:
	if not run_state.relation_states.has(character_id):
		return
	var state: Dictionary = run_state.relation_states[character_id]
	state["favor"] = int(state.get("favor", 0)) + delta
	state["stage_label"] = GameRules.relation_label(int(state["favor"]))
	run_state.relation_states[character_id] = state
	emit_signal("relation_changed", character_id)

func add_rumor_risk(run_state: RunState, character_id: String, delta: int) -> void:
	if not run_state.relation_states.has(character_id):
		return
	var state: Dictionary = run_state.relation_states[character_id]
	state["rumor_risk"] = maxi(0, int(state.get("rumor_risk", 0)) + delta)
	run_state.relation_states[character_id] = state
	emit_signal("relation_changed", character_id)

func describe_relation(run_state: RunState, character_id: String) -> String:
	if not run_state.relation_states.has(character_id):
		return TextDB.get_text("system.relations.steady")
	var state: Dictionary = run_state.relation_states[character_id]
	return TextDB.format_text(
		"system.relations.summary",
		[
			str(state.get("stage_label", TextDB.get_text("system.relations.steady"))),
			int(state.get("favor", 0)),
			int(state.get("rumor_risk", 0))
		]
	)
