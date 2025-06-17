# Player.gd (Attached to CharacterBody2D node of your Player scene)
extends CharacterBody2D
signal player_dead # Emitted when player collides with something that causes death

@export var speed = 200.0 # This speed will be effectively overridden by RL agent output,
						   # but can serve as a fallback or for debugging manual control.

func _physics_process(delta: float) -> void:
	# Player movement is now controlled externally by the RL agent,
	# which sets 'velocity' directly on this CharacterBody2D.
	# The manual input handling is removed here.
	move_and_slide()

# This function is intended to be called by another script (e.g., an obstacle's script
# or a collision detection area in Main.gd) when the player is "damaged" or collides.
func player_damage() -> void:
	# Emit the signal to notify the Main scene that the player has died.
	player_dead.emit()
	print("dead")
	# Optional: You might want to temporarily hide the player or play a death animation here
	# before the Main scene handles the full restart.
	# For RL training, the environment reset typically handles the "death" state.
