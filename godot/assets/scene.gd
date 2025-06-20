# Main.gd (Your main scene script)
extends Node2D

# --- RL Integration Parameters ---
@export var max_observable_obstacles = 10 # Adjust based on your game's density
var observation_space_size: int = 2 + (max_observable_obstacles * 2)
var action_space_size: int = 2 # (x_velocity_norm, y_velocity_norm)

# --- Game State and Node References ---
var score :int= 0
var high_score :int = 0 # To track the high score for the +5 bonus

@onready var player_node = $Player # Reference to your CharacterBody2D player
@onready var ref_pos = $ref_pos   # Reference to your ref_pos Node2D reference position if i need when tiling this instance
@onready var obstacle_spawner = $"obstacle spawner" # Reference to your obstacle spawner node
@onready var collision_area = $Area2D # This is to clear out obstacles near spawn when it dies

@onready var survival_reward_timer = $SurvivalRewardTimer # Timer for per-second reward
@onready var velocity_line = $VelocityLine2D # Line2D for player velocity visualization
@onready var nearest_obstacles_line = $NearestObstaclesLine2D # Line2D for lines to nearest obstacles

var screen_size: Vector2 # Will store the size of the game window
var game_running = true # Game state variable
var current_episode_reward: float = 0.0 # Accumulator for rewards in the current episode

# --- Pre-calculated for normalization ---
var window_width: float = 1280.0
var window_height: float = 720.0

# --- Functions called by the RL framework ---

# Gets the current observation for the RL agent
func get_obs() -> Array: # Renamed from get_observation to get_obs
	var observation = []

	# 1. Player's normalized position (relative to screen_size, from 0 to 1)
	if is_instance_valid(player_node): # Robustness check
		observation.append(player_node.position.x / window_width)
		observation.append(player_node.position.y / window_height)
	else:
		# Fallback if player_node is not ready or has been freed
		printerr("WARNING: get_obs called but Player node is invalid!")
		observation.append(0.0)
		observation.append(0.0)

	# 2. Positions of active obstacles (normalized)
	var obstacles_found = 0
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		if is_instance_valid(obstacle): # Robustness check
			if obstacles_found >= max_observable_obstacles:
				break # Limit to max_observable_obstacles
			observation.append(obstacle.position.x / window_width)
			observation.append(obstacle.position.y / window_height)
			obstacles_found += 1

	# Pad with zeros if fewer obstacles than max_observable_obstacles are found
	while obstacles_found < max_observable_obstacles:
		observation.append(0.0) # x
		observation.append(0.0) # y
		obstacles_found += 1
	
	return observation

# Applies the actions received from the RL agent to the player
# x_norm, y_norm are expected to be between -1 and 1
func apply_agent_action(x_norm: float, y_norm: float) -> void:
	if is_instance_valid(player_node) and game_running: # Robustness check
		var max_player_speed = 300.0 # Adjust this max speed as appropriate for your game
		player_node.velocity = Vector2(x_norm, y_norm).normalized() * max_player_speed
	elif is_instance_valid(player_node): # If game not running but player still exists
		player_node.velocity = Vector2.ZERO # Stop movement
	# else: player_node is null, nothing to do

# Returns the current reward and if the episode is done
func get_reward_and_done() -> Dictionary:
	var reward_info = {
		"reward": current_episode_reward,
		"done": not game_running
	}
	# IMPORTANT: Do NOT reset current_episode_reward here. It is reset in restart_game().
	return reward_info


# --- Godot Lifecycle Functions ---

func _ready() -> void:
	# Initialize screen_size
	screen_size = get_viewport_rect().size
	window_width = screen_size.x
	window_height = screen_size.y

	# Comprehensive null checks for all @onready nodes
	if not is_instance_valid(player_node): printerr("ERROR: @onready Player node ('$Player') not found! Game cannot run without player.")
	if not is_instance_valid(ref_pos): printerr("ERROR: @onready ref_pos node ('$ref_pos') not found! Check scene tree.")
	if not is_instance_valid(obstacle_spawner): printerr("ERROR: @onready obstacle spawner node ('$\"obstacle spawner\"') not found! Obstacles won't spawn.")
	if not is_instance_valid(collision_area): printerr("ERROR: @onready Area2D node ('$Area2D') not found! Player collision checks might fail.")

	# Set up survival reward timer with null check
	if is_instance_valid(survival_reward_timer):
		survival_reward_timer.wait_time = 1.0 # 1 second
		survival_reward_timer.autostart = true
		survival_reward_timer.timeout.connect(_on_survival_reward_timer_timeout)
	else:
		printerr("ERROR: 'SurvivalRewardTimer' node ('$SurvivalRewardTimer') not found! Please add a Timer node named 'SurvivalRewardTimer' as a direct child of Main. Reward over time will not function.")

	# Ensure Line2D nodes exist and are configured
	if not is_instance_valid(velocity_line):
		printerr("ERROR: 'VelocityLine2D' node ('$VelocityLine2D') not found! Please add a Line2D node named 'VelocityLine2D' as a direct child of Main. Velocity visualization will not work.")
	if not is_instance_valid(nearest_obstacles_line):
		printerr("ERROR: 'NearestObstaclesLine2D' node ('$NearestObstaclesLine2D') not found! Please add a Line2D node named 'NearestObstaclesLine2D' as a direct child of Main. Obstacle proximity visualization will not work.")

	print("Main scene loaded. RL integration ready.")
	print("Observation space size: ", observation_space_size)
	print("Action space size: ", action_space_size)

	# Initial restart to set up player
	restart_game()

func _physics_process(delta: float) -> void:
	update_visualizations()



# Helper function to clear all obstacles (used on restart)
func _clear_all_obstacles() -> void:
	# Assumes obstacles are added to the "obstacles" group
	var obstacles_to_clear = get_tree().get_nodes_in_group("obstacles")
	for obstacle in obstacles_to_clear:
		if is_instance_valid(obstacle): # Prevent errors if obstacle is already freeing
			obstacle.queue_free()

func restart_game() -> void:
	print("Restarting game...")
	score = 0
	current_episode_reward = 0.0 # Reset episode reward accumulator here, only on restart
	
	if is_instance_valid(player_node): # Robustness check
		player_node.velocity = Vector2(0,0)
		# Reposition player to a fixed starting point or randomized on Y
		player_node.set_position(Vector2(80, screen_size.y / 2 + randi_range(-100,100)))
	else:
		printerr("ERROR: Player node is not valid on restart! Ensure 'Player' CharacterBody2D is a child of Main.")
	
	_clear_all_obstacles() # Clear all existing obstacles. This is the primary way.
	
	if is_instance_valid(obstacle_spawner): # Robustness check
		obstacle_spawner.reset_spawn() # Your obstacle spawner's reset method
	else:
		printerr("ERROR: 'obstacle spawner' node not found on restart! Obstacles will not reset/spawn.")
	
	game_running = true
	print("Game restarted.")


# This signal is assumed to be emitted from the Player (CharacterBody2D) script when it collides
func _on_Player_player_dead() -> void:
	if game_running:
		print("Player died!")
		game_running = false
		current_episode_reward += -10.0 # Collision punishment
		# --- TEMPORARY DEBUG: Force restart for testing without RL agent ---
		# REMOVE THIS LINE WHEN TRAINING WITH YOUR EXTERNAL RL AGENT!
		restart_game()
		# --- END TEMPORARY DEBUG ---
		# The RL framework will call get_reward_and_done() and then trigger a reset.
		# So, no direct restart_game() call here for RL training normally.

func _on_survival_reward_timer_timeout() -> void:
	if game_running:
		current_episode_reward += 0.1 # Small reward every second
		# Increment score, assuming score tracks survival time
		score += 1

		# Check for high score bonus
		if score > high_score and score >= 50:
			current_episode_reward += 5.0 # High score bonus
			high_score = score
			print("New high score! +5 reward. High Score: ", high_score)

# --- Visualization Functions ---

func update_visualizations() -> void:
	if not is_instance_valid(player_node):
		return

	# Clear previous lines
	if is_instance_valid(velocity_line):
		velocity_line.clear_points()
	if is_instance_valid(nearest_obstacles_line):
		nearest_obstacles_line.clear_points()

	# 1. Visualize Player Velocity
	if is_instance_valid(velocity_line) and player_node.velocity.length() > 0:
		var start_point = player_node.position
		var end_point = player_node.position + player_node.velocity.normalized() * 50 # Draw a line 50 pixels long in velocity direction
		velocity_line.add_point(start_point)
		velocity_line.add_point(end_point)
		velocity_line.set_default_color(Color.BLUE) # Set color
		velocity_line.width = 3 # Set line thickness

	# 2. Visualize Lines to Nearest Obstacles
	if is_instance_valid(nearest_obstacles_line):
		var player_pos = player_node.position
		var obstacles = get_tree().get_nodes_in_group("obstacles")
		
		# Filter for valid instances before sorting and drawing
		var valid_obstacles = []
		for obs in obstacles:
			if is_instance_valid(obs):
				valid_obstacles.append(obs)

		# Sort obstacles by distance to player
		valid_obstacles.sort_custom(func(a, b): return player_pos.distance_squared_to(a.position) < player_pos.distance_squared_to(b.position))

		# Draw lines to the 3 nearest obstacles (or fewer if less exist)
		var num_lines_to_draw = min(3, valid_obstacles.size()) # Draw lines to up to 3 nearest
		for i in range(num_lines_to_draw):
			var obstacle = valid_obstacles[i]
			nearest_obstacles_line.add_point(player_pos)
			nearest_obstacles_line.add_point(obstacle.position)
		
		nearest_obstacles_line.set_default_color(Color.RED) # Set color
		nearest_obstacles_line.width = 2 # Set line thickness
