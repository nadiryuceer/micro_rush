class_name GameManager
extends Node

# Simple game manager that just handles main menu instantiation
# All factory logic moved to GameFactory static class

func _ready():
	instantiate_main_menu()

func instantiate_main_menu():
	var main_menu_scene = preload("res://scenes/menus/main_menu.tscn")
	var main_menu = main_menu_scene.instantiate()
	add_child(main_menu)
