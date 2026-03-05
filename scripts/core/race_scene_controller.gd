extends Node3D

var race_mode: String = ""
var map_name: String = ""

func _ready():
	# Get race parameters from scene metadata
	race_mode = get_tree().current_scene.get_meta("race_mode", "elimination")
	map_name = get_tree().current_scene.get_meta("map_name", "kitchen")
	
	setup_race(race_mode, map_name)

func setup_race(mode: String, map: String):
	race_mode = mode
	map_name = map
	
	print("Setting up race: ", race_mode, " on ", map_name)
	
	# Create race components using GameFactory static methods
	# Add track
	print("Creating track...")
	var track = GameFactory.create_track(map_name)
	if track:
		add_child(track)
		print("Track created and added to scene")
	else:
		print("ERROR: Failed to create track")
	
	# Add camera rig
	print("Creating camera rig...")
	var camera_rig = GameFactory.create_camera_rig()
	if camera_rig:
		add_child(camera_rig)
		print("Camera rig created and added to scene")
	else:
		print("ERROR: Failed to create camera rig")
	
	# Add player vehicle
	print("Creating player vehicle...")
	var player_vehicle = GameFactory.create_player_vehicle()
	if player_vehicle:
		add_child(player_vehicle)
		print("Player vehicle created and added to scene")
		# Add vehicle to camera
		if camera_rig and camera_rig.get("players"):
			camera_rig.players.append(player_vehicle)
			print("Vehicle added to camera follow list")
		else:
			print("WARNING: Could not add vehicle to camera")
	else:
		print("ERROR: Failed to create player vehicle")
	
	print("Race setup complete: ", race_mode, " on ", map_name)
