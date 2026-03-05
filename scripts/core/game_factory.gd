class_name GameFactory
extends RefCounted

# Static factory for creating game scenes
# No instance needed - all methods are static

static func create_race_scene(race_mode: String, map_name: String) -> Node:
	var race_scene = Node.new()
	race_scene.name = "RaceScene"
	
	# Add track
	var track = create_track(map_name)
	if track:
		race_scene.add_child(track)
	
	# Add camera rig
	var camera_rig = create_camera_rig()
	if camera_rig:
		race_scene.add_child(camera_rig)
	
	# Add player vehicle
	var player_vehicle = create_player_vehicle()
	if player_vehicle:
		race_scene.add_child(player_vehicle)
		# Add vehicle to camera
		if camera_rig and camera_rig.get("players"):
			camera_rig.players.append(player_vehicle)
	
	return race_scene

static func create_track(map_name: String) -> Node3D:
	match map_name:
		"kitchen":
			var kitchen_scene = preload("res://scenes/game/kitchen_track.tscn")
			return kitchen_scene.instantiate()
		_:
			push_error("Unknown map: " + map_name)
			return null

static func create_camera_rig() -> Node:
	var camera_scene = preload("res://scenes/game/camera_rig.tscn")
	return camera_scene.instantiate()

static func create_player_vehicle(vehicle_id: String = "ambulance") -> BaseVehicle:
	# Load vehicle data directly
	var vehicle_data = VehicleFactory.load_vehicle_data(vehicle_id)
	if not vehicle_data:
		push_error("Vehicle not found: " + vehicle_id)
		return null
	
	var vehicle = VehicleFactory.create_vehicle(vehicle_data)
	if vehicle:
		vehicle.global_position = Vector3(0, 1, 0)
	
	return vehicle
