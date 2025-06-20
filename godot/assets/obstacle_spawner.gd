extends Node2D
@export var obstacle_scene: PackedScene # Drag your Obstacle.tscn here in the Inspector
@export var spawn_interval = 1.0 # How often obstacles spawn (seconds)

@onready var spawn_timer = $SpawnTimer # Reference to your Timer node
@onready var obs_holder = $obs_holder
var game_running :bool = true
func _ready() -> void:
	# Set up the spawn timer
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true # Automatically start the timer when the scene loads

	# Connect the timeout signal of the timer to a function
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

# Function to spawn an obstacle
func spawn_obstacle() -> void:
	if not game_running:
		return
	#print("spawn")
	var new_obstacle = obstacle_scene.instantiate()
	obs_holder.add_child(new_obstacle)
	# Randomly position the obstacle
	var spawn_prog_ratio = randf()
	$Path2D/PathFollow2D.progress_ratio = spawn_prog_ratio
	new_obstacle.position = ($Path2D/PathFollow2D.get_global_position())

# Called when the spawn timer times out
func _on_spawn_timer_timeout() -> void:
	for i in randi_range(1,4):
		spawn_obstacle()

func stop_spawn():
	game_running = false
	print("kill")
	print(obs_holder.get_path())
	print_tree()
	#for i in obs_holder.get_children():
		#if i.has_method("kill_obstacles"):
			#i.kill_obstacles()
	#print(obs_holder.get_path())
	#print_tree()

func reset_spawn():
	game_running = true
