extends KinematicBody2D


const UP = Vector2(0,-1)
const GRAVITY = 20
const ACCELERATION = 50
const MAX_SPEED = 200
const JUMP_HEIGHT = -600
const DOUBLEJUMP_HEIGHT = -550
var motion = Vector2()
var doublejump = 1
var bounce = -800
# Called when the node enters the scene tree for the first time.


	
func _physics_process(delta):
	motion.y += GRAVITY
	var friction = false
	
	if Input.is_action_pressed("ui_right"):
		motion.x = min(motion.x+ACCELERATION, MAX_SPEED) 
		$Sprite.flip_h = false
		$Sprite.play("run")
	elif Input.is_action_pressed("ui_left"):
		motion.x = max(motion.x-ACCELERATION, -MAX_SPEED) 
		$Sprite.flip_h = true
		$Sprite.play("run")
	else:
		$Sprite.play("idle")
		friction = true
		
	

	if is_on_floor():
		doublejump = 1
		if Input.is_action_just_pressed("ui_up"):
			motion.y = JUMP_HEIGHT
			
		if friction == true:
			motion.x = lerp(motion.x, 0, 0.2)

	else:
		if is_on_wall():
			motion.y = lerp(motion.y, 0, 0.1) #slow descent

		if Input.is_action_just_pressed("ui_up") && doublejump == 1:
			motion.y = DOUBLEJUMP_HEIGHT
			doublejump -=1
		if motion.y < 0:
			$Sprite.play("jump")
		else:
			if is_on_wall():
				$Sprite.play("slowfall")
			else:
				$Sprite.play("fall")
		if friction == true:
			motion.x = lerp(motion.x, 0, 0.05)
	motion = move_and_slide(motion, UP)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _input(event : InputEvent):
	if (event.is_action_pressed("ui_down") && is_on_floor()):
		position.y+= 1




func _on_Bounce_body_entered(body):
	motion.y = bounce
