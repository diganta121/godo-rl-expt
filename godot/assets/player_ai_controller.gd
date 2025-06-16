extends AIController2D
func get_obs() -> Dictionary:
	# Return observations (e.g., player position, environment state)
	return {"obs": []}

func get_reward() -> float:
	# Define the reward (e.g., +1 for reaching a goal)
	return 0.0

func get_action_space() -> Dictionary:
	# Define action space (continuous or discrete)
	return {
		"example_actions_continuous": {
			"size": 2,
			"action_type": "continuous"
		},
		"example_actions_discrete": {
			"size": 2,
			"action_type": "discrete"
		}
	}

func set_action(action) -> void:
	# Apply the action (e.g., move character based on action values)
	pass
