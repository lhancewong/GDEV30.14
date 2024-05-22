extends Resource
class_name BattlerStats

enum BattlerType {
	PLAYER,
	ENEMY,
}

@export var sprite: Texture
@export var type: BattlerType
@export var max_hp: int
@export var min_damage: int
@export var max_damage: int
@export var turn_speed: int
@export var skill_index: int
