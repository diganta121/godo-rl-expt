extends CharacterBody2D
signal player_dead
@export var speed = 200.0 # Player movement speed

func _physics_process(delta: float) -> void:
	# Get input direction
	var direction = Vector2.ZERO
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("up"):
		direction.y -= 1

	# Normalize direction to prevent faster diagonal movement
	if direction.length() > 0:
		direction = direction.normalized()

	# Calculate velocity
	velocity = direction * speed

	# Move the character
	move_and_slide()

func player_damage():
	player_dead.emit()
	
