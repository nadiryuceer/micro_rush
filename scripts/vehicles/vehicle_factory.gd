class_name VehicleFactory
extends Node

# Static factory methods for creating vehicles from data
static func create_vehicle(vehicle_data: VehicleData, is_ai: bool = false) -> BaseVehicle:
	var vehicle_scene: PackedScene
	
	if is_ai:
		vehicle_scene = preload("res://templates/vehicles/ai_vehicle_base.tscn")
	else:
		vehicle_scene = preload("res://templates/vehicles/vehicle_base.tscn")
	
	var vehicle: BaseVehicle = vehicle_scene.instantiate()
	vehicle.setup_from_data(vehicle_data)
	
	return vehicle

static func load_vehicle_data(vehicle_id: String) -> VehicleData:
	var data_path = "res://data/vehicles/individual_vehicles/%s.json" % vehicle_id
	
	if not FileAccess.file_exists(data_path):
		push_error("Vehicle data not found: " + vehicle_id)
		return null
	
	var file = FileAccess.open(data_path, FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("Failed to parse vehicle data: " + vehicle_id)
		return null
	
	var data_dict = json.data
	return create_vehicle_data_from_dict(data_dict)

static func create_vehicle_data_from_dict(data_dict: Dictionary) -> VehicleData:
	var vehicle_data = VehicleData.new()
	
	# Basic info
	vehicle_data.vehicle_id = data_dict.get("vehicle_id", "")
	vehicle_data.display_name = data_dict.get("display_name", "")
	vehicle_data.description = data_dict.get("description", "")
	
	# Visual data
	vehicle_data.mesh_path = data_dict.get("mesh_path", "")
	vehicle_data.vehicle_type = data_dict.get("vehicle_type", 0)
	vehicle_data.size_category = data_dict.get("size_category", 1)
	
	# Physics data
	#vehicle_data.collision_size = Vector3(
	#	data_dict.get("collision_size", {}).get("x", 2.0),
#		data_dict.get("collision_size", {}).get("y", 1.0),
#		data_dict.get("collision_size", {}).get("z", 4.0)
#	)
	
	# Wheel data
	var wheel_positions = data_dict.get("wheel_positions", [])
	vehicle_data.wheel_positions.clear()
	
	for pos_dict in wheel_positions:
		vehicle_data.wheel_positions.append(Vector3(
			pos_dict.get("x", 0.0),
			pos_dict.get("y", 0.0),
			pos_dict.get("z", 0.0)
		))
	
	# Stats
	var stats_dict = data_dict.get("vehicle_stats", {})
	vehicle_data.vehicle_stats = VehicleStats.new()
	if vehicle_data.vehicle_stats:
		vehicle_data.vehicle_stats.max_speed = stats_dict.get("max_speed", 6.0)
		vehicle_data.vehicle_stats.acceleration = stats_dict.get("acceleration", 6.5)
		vehicle_data.vehicle_stats.steering_speed = stats_dict.get("steering_speed", 3.2)
		vehicle_data.vehicle_stats.grip = stats_dict.get("grip", 18.0)
		vehicle_data.vehicle_stats.boost_force = stats_dict.get("boost_force", 35.0)
		vehicle_data.vehicle_stats.drag = stats_dict.get("drag", 6.0)
		vehicle_data.vehicle_stats.weight = stats_dict.get("weight", 1.0)
		
		# Apply size-based modifiers
		vehicle_data.vehicle_stats.apply_size_modifier(vehicle_data.size_category)
	else:
		push_error("Failed to create VehicleStats for vehicle: " + vehicle_data.vehicle_id)
	
	return vehicle_data

static func get_all_available_vehicles() -> Array[String]:
	var vehicles: Array[String] = []
	var dir = DirAccess.open("res://data/vehicles/individual_vehicles/")
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				var vehicle_id = file_name.get_basename()
				vehicles.append(vehicle_id)
			file_name = dir.get_next()
	
	return vehicles
