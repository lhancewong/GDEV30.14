extends Node2D

@onready var ray = %RayCast2D
@onready var asprite_anchor = $Anchor
@onready var asprite = %AnimatedSprite2D
@onready var tile_map = %TileMap

var moving = false

var walking_speed = 2
var tile_size = 16
var input_buffer = [Vector2.ZERO]
var input_buffer_readout = Vector2()


func _physics_process(delta):
	if moving == false:
		return

	if global_position == asprite_anchor.global_position:
		moving = false
		return

	asprite_anchor.global_position = asprite_anchor.global_position.move_toward(
		global_position, walking_speed
	)


func _process(delta):
	read_input()

	if moving:
		return

	if input_buffer_readout == Vector2.ZERO:
		asprite.stop()
		return

	move(input_buffer_readout)
	animate(input_buffer_readout)


func move(dir):
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(
		current_tile.x + dir.x,
		current_tile.y + dir.y,
	)

	ray.target_position = dir * tile_size
	ray.force_raycast_update()

	if ray.is_colliding():
		return

	moving = true
	global_position = tile_map.map_to_local(target_tile)
	asprite_anchor.global_position = tile_map.map_to_local(current_tile)


func animate(dir):
	if dir == Vector2.RIGHT:
		asprite.play("player_walk_right")
	elif dir == Vector2.LEFT:
		asprite.play("player_walk_left")
	elif dir == Vector2.UP:
		asprite.play("player_walk_up")
	elif dir == Vector2.DOWN:
		asprite.play("player_walk_down")


func read_input():
	if Input.is_action_just_pressed("player_walk_right"):
		input_buffer.append(Vector2.RIGHT)
	elif Input.is_action_just_pressed("player_walk_left"):
		input_buffer.append(Vector2.LEFT)
	elif Input.is_action_just_pressed("player_walk_up"):
		input_buffer.append(Vector2.UP)
	elif Input.is_action_just_pressed("player_walk_down"):
		input_buffer.append(Vector2.DOWN)

	if Input.is_action_just_released("player_walk_right"):
		input_buffer.erase(Vector2.RIGHT)
	elif Input.is_action_just_released("player_walk_left"):
		input_buffer.erase(Vector2.LEFT)
	elif Input.is_action_just_released("player_walk_up"):
		input_buffer.erase(Vector2.UP)
	elif Input.is_action_just_released("player_walk_down"):
		input_buffer.erase(Vector2.DOWN)

	input_buffer_readout = input_buffer[-1]
