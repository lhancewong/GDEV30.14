extends Node2D

@export var stats_resource: BattlerStats

@onready var sprite_2d = $Sprite2D
@onready var health_bar = %HealthBar

@onready var turn_indicator_animation = %TurnIndicatorAnimation
@onready var hit_fx_animation = %HitFXAnimation
@onready var animation_player = %AnimationPlayer
@onready var heal_fx_animation = $HealFXAnimation
@onready var selected_target_button = %SelectedTargetButton

var current_hp: int

signal be_selected(this_target: Node2D)
signal dead(this_battler: Node2D)
signal deal_damage(damage: int)


func _ready():
	selected_target_button.hide()
	stop_turn()

	current_hp = stats_resource.max_hp
	sprite_2d.texture = stats_resource.sprite

	selected_target_button.pressed.connect(_on_select_button_pressed)

	_update_health_bar()


func _update_health_bar() -> void:
	health_bar.max_value = stats_resource.max_hp
	health_bar.value = current_hp


func start_turn() -> void:
	turn_indicator_animation.play("in_turn")
	if (randi() % 50) >= 20:
		_play_heal_anim()
		await get_tree().create_timer(0.6).timeout
		_heal_self()
	_play_attack_anim()
	await get_tree().create_timer(0.6).timeout
	deal_damage.emit(_get_attack_damage())


func stop_turn() -> void:
	turn_indicator_animation.play("RESET")
	animation_player.play("RESET")
	hit_fx_animation.play("RESET")
	heal_fx_animation.play("RESET")


func _on_select_button_pressed() -> void:
	be_selected.emit(self)


func show_select_button() -> void:
	selected_target_button.show()


func hide_select_button() -> void:
	selected_target_button.hide()


func _play_attack_anim() -> void:
	animation_player.play("attack")


func _play_heal_anim() -> void:
	heal_fx_animation.play("heal")


func _get_attack_damage() -> int:
	return randi_range(stats_resource.min_damage, stats_resource.max_damage)


func _heal_self() -> void:
	current_hp += 300
	_update_health_bar()


func play_hit_fx_anim() -> void:
	hit_fx_animation.play("play")


func be_damaged(amount: int) -> void:
	current_hp -= amount
	_update_health_bar()
	if current_hp <= 0:
		current_hp = 0
		dead.emit(self)
		queue_free()
