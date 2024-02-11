extends Node2D

@onready var ray = %RayCast2D
@onready var asprite_anchor = $Anchor
@onready var asprite = %AnimatedSprite2D
@onready var tile_map = %TileMap
@onready var player_camera = %Camera2D
@onready var transition_camera = $"../TransitionCamera"

var tile_size = 16
var walking_speed = 1
var moving = false
var camera_transitioning = false

var input_buffer = [Vector2.ZERO]
var input_buffer_readout = Vector2()


# Called when node first enters the scene
func _ready():
	process_tile_data()
	player_camera.make_current()


# Handles incrementing the player's position
func _physics_process(delta):
	# If player doesn't want to move, return
	if moving == false:
		return

	# Made it to the target tile, stop moving, check for tile movement logic
	if global_position == asprite_anchor.global_position:
		moving = false
		process_tile_data()
		return

	# Move sprite toward target tile with walking speed
	asprite_anchor.global_position = asprite_anchor.global_position.move_toward(
		global_position, walking_speed
	)


# Handles reading movement input
func _process(delta):
	read_input()

	# If player or camera is moving don't accept input
	if moving or camera_transitioning:
		return

	# If player isn't moving, stop animations
	if input_buffer_readout == Vector2.ZERO:
		asprite.stop()
		return

	# Move based on latest input
	move(input_buffer_readout)


# Handles movement logic
func move(dir):
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var target_tile: Vector2i = Vector2i(
		current_tile.x + dir.x,
		current_tile.y + dir.y,
	)

	# Point RayCast to movement direction
	ray.target_position = dir * tile_size
	ray.force_raycast_update()

	# If theres a wall in movement direction don't move
	if ray.is_colliding():
		return

	moving = true
	# Sets the player's location to target tile
	global_position = tile_map.map_to_local(target_tile)
	# Sets the player's sprite back to the previous tile to be animated
	asprite_anchor.global_position = tile_map.map_to_local(current_tile)
	animate(dir)


# Teleports to a door at map_coord
func teleport_to_door(map_coord: Vector2i):
	if camera_transitioning:
		return

	# Moves the transition_camera position to the player_camera position
	transition_camera.global_position = player_camera.global_position
	# Sets player global position to map_coord
	global_position = tile_map.map_to_local(map_coord)

	# Smoothly transitions the player's viewport to map_coord using a Tween
	camera_transitioning = true
	transition_camera.make_current()
	var tween = create_tween()
	tween.tween_property(transition_camera, "global_position", global_position, 0.5)
	await tween.finished
	camera_transitioning = false

	# Sets the player_camera back to the current camera
	player_camera.make_current()
	move(Vector2.DOWN)


# Handles player movement animations
func animate(dir):
	if dir == Vector2.RIGHT:
		asprite.play("player_walk_right")
	elif dir == Vector2.LEFT:
		asprite.play("player_walk_left")
	elif dir == Vector2.UP:
		asprite.play("player_walk_up")
	elif dir == Vector2.DOWN:
		asprite.play("player_walk_down")


# Handles adding input to an input buffer for smoother movement
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

	# Most recent input
	input_buffer_readout = input_buffer[-1]


# Checks what to do when stepping on a tile
func process_tile_data():
	var current_tile: Vector2i = tile_map.local_to_map(global_position)
	var tile_data: TileData = tile_map.get_cell_tile_data(0, current_tile)

	if tile_data.get_custom_data("type") == 0:  # Stepped on a regular tile
		walking_speed = 1
	elif tile_data.get_custom_data("type") == 1:  # Stepped on a path tile
		walking_speed = 1.5
	elif tile_data.get_custom_data("type") == 8:  # Stepped on door1 at (4,5)
		teleport_to_door(Vector2i(54, 4))
	elif tile_data.get_custom_data("type") == 9:  # Stepped on door2 at (54, 4)
		teleport_to_door(Vector2i(4, 5))
