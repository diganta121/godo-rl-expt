extends Node2D

var score :int= 0

@onready var player = $Player # Reference to your Player node

var screen_size: Vector2 # Will store the size of the game window
var game_running = true # Game state variable

var global_x :int = 0
var global_y :int = 0

func _ready() -> void:
	global_x = $ref_pos.get_position().x
	global_y = $ref_pos.get_position().y
	


func show_game_over_message() -> void:
	var message_box = Label.new()
	message_box.text = "GAME OVER!\nPress R to Restart"
	message_box.add_theme_font_size_override("font_size", 48)
	message_box.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_box.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_box.modulate = Color(1, 0, 0, 1) # Red color for text
	message_box.set_as_top_level(true) # Ensure it renders above everything
	add_child(message_box)



func restart_game() -> void:
	score = 0
	$Player.velocity = Vector2(0,0)
	$Player.set_position(Vector2(80,350 + randi_range(-100,100)))
	#$Player.y = global_y +350 + randi_range(-100,100)
	$"obstacle spawner".reset_spawn()
	game_running = true
	var overlapping_areas = $Area2D.get_overlapping_areas()
	for body in overlapping_areas:
		if body.has_method("kill_obstacles"):
			body.kill_obstacles()


func _on_character_body_2d_player_dead() -> void:
	if game_running:
		game_running = false
		#show_game_over_message()
		restart_game()
		#$"obstacle spawner".stop_spawn()
