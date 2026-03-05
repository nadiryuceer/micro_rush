extends Control

@onready var elimination_button: Button = $VBoxContainer/EliminationButton
@onready var time_trial_button: Button = $VBoxContainer/TimeTrialButton
@onready var back_button: Button = $VBoxContainer/BackButton

func _ready():
	add_to_group("menus")
	elimination_button.pressed.connect(_on_elimination_pressed)
	time_trial_button.pressed.connect(_on_time_trial_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_elimination_pressed():
	print("Going to map selection for Elimination mode...")
	# Store race mode in a simple way that the next scene can access
	get_tree().current_scene.set_meta("pending_race_mode", "elimination")
	get_tree().change_scene_to_file("res://scenes/menus/map_selection_menu.tscn")

func _on_time_trial_pressed():
	print("Going to map selection for Time Trial mode...")
	# Store race mode in a simple way that the next scene can access
	get_tree().current_scene.set_meta("pending_race_mode", "time_trial")
	get_tree().change_scene_to_file("res://scenes/menus/map_selection_menu.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
