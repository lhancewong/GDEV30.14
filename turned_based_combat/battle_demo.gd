extends Node

@onready var turn_action_buttons = %TurnActionButtons
@onready var attack_button = %AttackButton
@onready var self_heal_button = %SelfHealButton
@onready var block_button = %BlockButton
@onready var skill_button = %SkillButton
@onready var skip_turn_button = %SkipTurnButton
@onready var battle_end_panel = %BattleEndPanel
@onready var battle_end_text = %BattleEndText

var all_battlers = []
var player_battlers = []
var enemy_battlers = []

var current_turn: Node2D
var current_turn_index: int


func _ready() -> void:
	turn_action_buttons.hide()
	battle_end_panel.hide()

	player_battlers = get_tree().get_nodes_in_group("PlayerBattler")
	enemy_battlers = get_tree().get_nodes_in_group("EnemyBattler")
	all_battlers.append_array(player_battlers)
	all_battlers.append_array(enemy_battlers)

	all_battlers.sort_custom(_sort_turn_order_ascending)

	skip_turn_button.pressed.connect(_next_turn)
	self_heal_button.pressed.connect(_heal_player)
	block_button.pressed.connect(_block_player)
	skill_button.pressed.connect(_cast_skill_player)
	attack_button.pressed.connect(_show_target_buttons)

	for p in player_battlers:
		p.turn_ended.connect(_next_turn)
		p.dead.connect(_on_player_dead)

	for e in enemy_battlers:
		e.be_selected.connect(_attack_selected_enemy)
		e.dead.connect(_on_enemy_dead)
		e.deal_damage.connect(_attack_random_player_battler)

	current_turn = all_battlers[current_turn_index]
	_update_turn()


func _sort_turn_order_ascending(battler_1, battler_2) -> bool:
	if battler_1.stats_resource.turn_speed < battler_2.stats_resource.turn_speed:
		return true
	return false


func _update_turn() -> void:
	if current_turn.stats_resource.type == BattlerStats.BattlerType.PLAYER:
		turn_action_buttons.show()
	else:
		turn_action_buttons.hide()

	current_turn.start_turn()


func _next_turn() -> void:
	if turn_action_buttons.visible:
		turn_action_buttons.hide()
	current_turn.stop_turn()
	if _check_for_battle_end() == false:
		current_turn_index = (current_turn_index + 1) % all_battlers.size()
		current_turn = all_battlers[current_turn_index]
		_update_turn()


func _show_target_buttons() -> void:
	turn_action_buttons.hide()
	for e in enemy_battlers:
		e.show_select_button()


func _hide_target_buttons() -> void:
	for e in enemy_battlers:
		e.hide_select_button()


func _attack_selected_enemy(selected_enemy: Node2D) -> void:
	_hide_target_buttons()
	current_turn.start_attacking(selected_enemy)


func _block_player() -> void:
	current_turn.block_self()


func _heal_player() -> void:
	current_turn.heal_self()


func _cast_skill_player() -> void:
	match current_turn.stats_resource.skill_index:
		1:  #knight skill
			for p in player_battlers:
				p.defended()
			await get_tree().create_timer(0.4).timeout
			current_turn.manual_end_turn()
		2:  #priest skill
			for p in player_battlers:
				p.healed()
			await get_tree().create_timer(1).timeout
			current_turn.manual_end_turn()
		3:  #texan skill
			for e in enemy_battlers:
				current_turn.special_attack(e)
				await get_tree().create_timer(0.9).timeout
			current_turn.manual_end_turn()


func _attack_random_player_battler(damage: int) -> void:
	var rand = randi_range(0, player_battlers.size() - 1)
	player_battlers[rand].play_hit_fx_anim()
	await get_tree().create_timer(0.6).timeout
	player_battlers[rand].be_damaged(damage)
	await get_tree().create_timer(0.3).timeout
	_next_turn()


func _on_enemy_dead(dead_enemy: Node2D) -> void:
	enemy_battlers.erase(dead_enemy)
	all_battlers.erase(dead_enemy)


func _on_player_dead(dead_battler: Node2D) -> void:
	player_battlers.erase(dead_battler)
	all_battlers.erase(dead_battler)


func _check_for_battle_end() -> bool:
	if enemy_battlers.is_empty():
		_show_battle_end_panel(
			"[center][wave amp=50.0 freq=5.0 connected=1][rainbow freq=1.0 sat=0.8 val=0.8]Player won!"
		)
		$CanvasLayer/BattleEndPanel/BattleEndWin.play()
		return true
	elif player_battlers.is_empty():
		_show_battle_end_panel(
			"[center][color=red][shake rate=20.0 level=5 connected=1]Player lost!"
		)
		$CanvasLayer/BattleEndPanel/BattleEndLose.play()
		return true
	return false


func _show_battle_end_panel(message: String) -> void:
	battle_end_text.clear()
	battle_end_text.append_text(message)
	battle_end_panel.show()
	if turn_action_buttons.visible:
		turn_action_buttons.hide()
