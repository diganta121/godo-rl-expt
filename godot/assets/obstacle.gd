extends Area2D

@export var speed = 100.0 # How fast the obstacles move (adjust as needed)

func _ready() -> void:
	# Add this obstacle to the "obstacles" group for easier detection
	add_to_group("obstacles")

func _physics_process(delta: float) -> void:
	# OBSTACLES NOW MOVE TOWARDS THE LEFT
	position.x -= speed * delta

	# Optionally, remove obstacles that go off-screen to save performance
	# Now checking if it's moved too far left
	if position.x < -50: # 50 pixels buffer beyond the left edge of the screen
		queue_free() # Deletes the obstacle instance

func kill_obstacles():
	queue_free()


func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	if body.has_method("player_damage"):
		body.player_damage()
