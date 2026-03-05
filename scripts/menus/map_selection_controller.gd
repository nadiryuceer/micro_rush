extends Control

@onready var kitchen_button: Button = $VBoxContainer/KitchenButton
@onready var back_button: Button = $VBoxContainer/BackButton

var race_mode: String = ""

func _ready():
	add_to_group("menus")
	kitchen_button.pressed.connect(_on_kitchen_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Get race mode from the scene parameter (passed from previous scene)
	race_mode = get_race_mode_from_previous_scene()
	$VBoxContainer/Title.text = "Select Map - " + race_mode.capitalize()

func get_race_mode_from_previous_scene() -> String:
	# Try to get race mode from the previous scene's metadata
	# This is a simple approach for passing data between scenes
	var previous_scene = get_tree().current_scene
	if previous_scene and previous_scene.has_meta("pending_race_mode"):
		return previous_scene.get_meta("pending_race_mode")
	return "elimination"  # Default fallback

func set_race_mode(mode: String):
	race_mode = mode
	$VBoxContainer/Title.text = "Select Map - " + mode.capitalize()

func _on_kitchen_pressed():
	print("Starting ", race_mode, " on Kitchen map...")
	
	# Set race parameters in scene metadata
	get_tree().current_scene.set_meta("race_mode", race_mode)
	get_tree().current_scene.set_meta("map_name", "kitchen")
	
	# Change to the race scene
	get_tree().change_scene_to_file("res://scenes/game/race_scene.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/race_mode_menu.tscn")
