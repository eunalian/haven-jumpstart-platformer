extends CharacterBody2D
@onready var pivot = $"Pivot"
@onready var sprites = $AnimatedSprite2D

const JUMP_VELOCITY = -700.0
var GRAVITY = 9.8
var ACCELERATION = 150
var AIR_ACCELERATION_MULTIPLIER = 0.1
var MAX_WALK_SPEED = 500
var FRICTION_MULT = 0.8
var AIR_FRICTION_MULT = 1


var external_launch_force = Vector2()
enum states {idle, walking, airborne, landing, hurt, death}
var player_state: states = states.idle

func launch_by_vector(vector = Vector2(0,0)):
	external_launch_force += vector
	
func launch_by_angle_and_magnitude(theta = 0, mag = 0):
	# this needs smth with the pythagoras theorem or some shit like that idk
	# so you have theta and the length of the hypoteneuse 
	# SOH CAH TOA on that thang
	# actually you just need soh and cah right
	# Cos needs to be first because ADJACENT calculates X axis magnitude
	# OPPOSITE calculates Y axis magnitude
	
	# for some reason i do not know, the Y axis component is so much more larger than the x axis, did i get my calculations wrong?
	# as of 6:49 PM I HAVE FOUND THE REASON!!!!!!!!! its because i clamped the velocity x to 500
	
	# note to self: theta is given in radians. most angle operations in godot use radians anyways.
	var launch_vector = Vector2(
		cos(theta) * mag,
		sin(theta) * mag
	)
	print(str(launch_vector * 20))
	external_launch_force += -launch_vector

func jump():
	# bro
	velocity.y += JUMP_VELOCITY

func state_handler():
	if not is_on_floor():
		player_state = states.airborne
	
	# checks if velocity is +-1
	elif velocity.x > 1 or velocity.x < -1:
		player_state = states.walking
	else:
		player_state = states.idle
	
func animation_player(player_state):
	match player_state:
		states.idle: sprites.play("idle")
		states.walking: sprites.play("walk")
		states.airborne: sprites.play("jump_start")
		states.hurt: sprites.play("hurt")
		states.death: sprites.play("death")

func _physics_process(delta: float) -> void:
	
	# MAKE THE THING LOOK AT THE MOUSE
	# make the player sprite face the mouse as well
	var mouse_pos = get_global_mouse_position()
	pivot.look_at(mouse_pos)
	
	# shorthand way to handle the flipping of sprites
	sprites.flip_h = (get_global_mouse_position().x < global_position.x)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta


	# Handle jump.
	if Input.is_action_pressed("jump") and is_on_floor():	
		jump()


	# direction returns 1 when pressed right and -1 when pressed left
	var direction = Input.get_axis("left", "right")
	
	# Handles acceleration when on the ground
	var current_speed = velocity.x
	var walking_force = 0
	
	# Accelerate by accelration value times the normal direction
	if is_on_floor():
		walking_force = ACCELERATION * direction
	# Same as above but with a multiplier to decrease control in the air
	else:
		walking_force = ACCELERATION * AIR_ACCELERATION_MULTIPLIER * direction
	current_speed += walking_force
	velocity.x = current_speed
	
	# handle friction (though there is no air friction)
	if is_on_floor():
		velocity.x = velocity.x * FRICTION_MULT
	else:
		velocity.x = velocity.x * AIR_FRICTION_MULT

	# check if some function has added a vector to the external launch force, then add it to the players velocity
	if external_launch_force:
		velocity += external_launch_force
		external_launch_force = Vector2(0,0)
	
	# Prints velocity for debugging 
	print('VEL: ' + str(velocity))
	
	
	# HANDLES ANIMATIONS AND PLAYER STATES
	var new_state = player_state
	state_handler()
	# only call animation player when player state has changed
	if new_state != player_state:
		animation_player(player_state)
	
	move_and_slide()
