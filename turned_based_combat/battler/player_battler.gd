extends Node2D

@export var stats_resource: BattlerStats

@onready var sprite_2d = $Sprite2D
@onready var health_bar = %HealthBar
@onready var shield = $Shield
@onready var potion = $Potion

@onready var turn_indicator_animation = %TurnIndicatorAnimation
@onready var heal_fx_animation = %HealFXAnimation
@onready var block_fx_animation = %BlockFXAnimation
@onready var hit_fx_animation = %HitFXAnimation
@onready var animation_player = %AnimationPlayer

var current_hp: int
var is_defended: bool

signal dead(this_battler: Node2D)
signal turn_ended


func _ready():
	shield.hide()
	potion.hide()
	stop_turn()

	current_hp = stats_resource.max_hp
	is_defended = false
	sprite_2d.texture = stats_resource.sprite

	_update_health_bar()


func _update_health_bar() -> void:
	health_bar.max_value = stats_resource.max_hp
	health_bar.value = current_hp


func start_turn() -> void:
	turn_indicator_animation.play("in_turn")


func stop_turn() -> void:
	turn_indicator_animation.play("RESET")
	animation_player.play("RESET")
	hit_fx_animation.play("RESET")
	heal_fx_animation.play("RESET")
	block_fx_animation.play("RESET")


func manual_end_turn() -> void:
	turn_ended.emit()


func special_attack(enemy_target: Node2D) -> void:
	_play_attack_anim()
	await get_tree().create_timer(0.4).timeout
	enemy_target.play_hit_fx_anim()
	await get_tree().create_timer(0.3).timeout
	enemy_target.be_damaged(_get_attack_damage())
	await get_tree().create_timer(0.1).timeout


func start_attacking(enemy_target: Node2D) -> void:
	_play_attack_anim()
	await get_tree().create_timer(0.4).timeout
	enemy_target.play_hit_fx_anim()
	await get_tree().create_timer(0.3).timeout
	enemy_target.be_damaged(_get_attack_damage())
	await get_tree().create_timer(0.1).timeout
	turn_ended.emit()


func block_self():
	block_fx_animation.play("block")
	await get_tree().create_timer(0.4).timeout
	is_defended = true
	turn_ended.emit()


func heal_self():
	heal_fx_animation.play("heal")
	await get_tree().create_timer(1).timeout
	current_hp += 200
	_update_health_bar()
	turn_ended.emit()


func healed():
	heal_fx_animation.play("heal")
	await get_tree().create_timer(1).timeout
	current_hp += 200
	_update_health_bar()


func defended():
	block_fx_animation.play("block")
	await get_tree().create_timer(0.4).timeout
	is_defended = true


func _play_attack_anim() -> void:
	animation_player.play("attack")


func _get_attack_damage() -> int:
	return randi_range(stats_resource.min_damage, stats_resource.max_damage)


func play_hit_fx_anim() -> void:
	hit_fx_animation.play("play")


func be_damaged(amount: int) -> void:
	if is_defended:
		is_defended = false
		block_fx_animation.play("unblock")
		return
	current_hp -= amount
	_update_health_bar()
	if current_hp <= 0:
		current_hp = 0
		dead.emit(self)
		queue_free()
