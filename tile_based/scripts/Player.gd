extends Area2D

@onready var ray = $RayCast2D
@onready var asprite = $AnimatedSprite2D

var animation_speed = 3
var moving = false
var tile_size = 16
var inputs = {
	"player_walk_right": Vector2.RIGHT,
	"player_walk_left": Vector2.LEFT,
	"player_walk_up": Vector2.UP,
	"player_walk_down": Vector2.DOWN,
}


func _ready():
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size / 2


func _physics_process(delta):
	if moving:
		return
	for dir in inputs.keys():
		if Input.is_action_pressed(dir):
			animate(dir)
			move(dir)


func move(dir):
	ray.target_position = inputs[dir] * tile_size
	ray.force_raycast_update()
	if !ray.is_colliding():
		#position += inputs[dir] * tile_size
		var tween = create_tween()
		(
			tween
			. tween_property(
				self, "position", position + inputs[dir] * tile_size, 1.0 / animation_speed
			)
			. set_trans(Tween.TRANS_SINE)
		)
		moving = true
		await tween.finished
		moving = false
		asprite.stop()


func animate(dir):
	asprite.play(dir)
