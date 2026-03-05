extends Control

@onready var race_button: Button = $VBoxContainer/RaceButton
@onready var options_button: Button = $VBoxContainer/OptionsButton

func _ready():
	add_to_group("menus")
	race_button.pressed.connect(_on_race_pressed)
	options_button.pressed.connect(_on_options_pressed)

func _on_race_pressed():
	get_tree().change_scene_to_file("res://scenes/menus/race_mode_menu.tscn")

func _on_options_pressed():
	print("Options menu - not implemented yet")
	# TODO: Implement options menu
