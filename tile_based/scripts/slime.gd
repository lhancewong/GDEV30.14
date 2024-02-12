extends Node2D

@onready var tile_map = %TileMap
@onready var ray_forward = $RayCastForward
@onready var ray_backward = $RayCastBackward
@onready var asprite = $AnimatedSprite2D

signal walked

var tile_size: int = 16
var moving: bool = false
var idling: bool = false
var dir_list = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.ZERO]

@export var walking_speed: float = 0.5


func _ready():
	asprite.play("default")

# Handles incrementing the player's position
func _physics_process(delta):
	# If player doesn't want to move, return
	if moving == false:
		return

	# Made it to the target tile, stop moving, check for tile movement logic
	if global_position == asprite.global_position:
		moving = false
		walked.emit()
		return

	# Move sprite toward target tile with walking speed
	asprite.global_position = asprite.global_position.move_toward(
		global_position, walking_speed
	)


# Handles reading movement input
func _process(delta):
	if moving or idling:
		return

	# Handles outlier behavior
	if ray_forward.is_colliding():
		move_back()
		await self.walked
	
	move_rand()
	await self.walked


# Handles movement logic
func move(dir):
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(
		current_tile.x + dir.x,
		current_tile.y + dir.y,
	)

	# Point RayCastForward to movement direction
	ray_forward.target_position = dir * tile_size
	ray_forward.force_raycast_update()

	# Point RayCastBackward opposite to movement direction
	ray_backward.target_position = Vector2(-dir.x, -dir.y) * tile_size
	ray_backward.force_raycast_update()
	
	# If theres a wall in movement direction don't move
	if ray_forward.is_colliding():
		return

	moving = true
	# Sets the player's location to target tile
	global_position = tile_map.map_to_local(target_tile)
	# Sets the player's sprite back to the previous tile to be animated
	asprite.global_position = tile_map.map_to_local(current_tile)


# Uses RayCastBackward to move the player backward
func move_back():
	var ray_dir: Vector2 = ray_backward.get_target_position()
	var move_dir: Vector2 = Vector2(ray_dir.x / 16, ray_dir.y / 16)
	move(move_dir)


# Moves in random directions
func move_rand():
	var rand_dir = dir_list[randi() % dir_list.size()]
	if rand_dir == Vector2.ZERO:
		idling = true
		await get_tree().create_timer(randi() % 4).timeout
		idling = false
	move(rand_dir)
