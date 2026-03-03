class_name VehicleDatabase
extends Node

# Central database for managing all vehicle data
var loaded_vehicles: Dictionary = {}  # vehicle_id -> VehicleData
var vehicle_categories: Dictionary = {}  # VehicleType -> Array[VehicleData]

signal vehicle_loaded(vehicle_id: String, vehicle_data: VehicleData)
signal database_loaded()

func _ready():
	load_all_vehicles()

func load_all_vehicles():
	var vehicle_ids = VehicleFactory.get_all_available_vehicles()
	
	for vehicle_id in vehicle_ids:
		var vehicle_data = VehicleFactory.load_vehicle_data(vehicle_id)
		if vehicle_data:
			loaded_vehicles[vehicle_id] = vehicle_data
			
			# Add to category
			var category = vehicle_data.vehicle_type
			if not vehicle_categories.has(category):
				vehicle_categories[category] = []
			vehicle_categories[category].append(vehicle_data)
			
			vehicle_loaded.emit(vehicle_id, vehicle_data)
	
	database_loaded.emit()

func get_vehicle(vehicle_id: String) -> VehicleData:
	return loaded_vehicles.get(vehicle_id, null)

func get_vehicles_by_type(vehicle_type: VehicleData.VehicleType) -> Array[VehicleData]:
	return vehicle_categories.get(vehicle_type, [])

func get_random_vehicle() -> VehicleData:
	var all_vehicles = loaded_vehicles.values()
	if all_vehicles.is_empty():
		return null
	
	return all_vehicles[randi() % all_vehicles.size()]

func get_vehicles_by_size(size_category: VehicleData.SizeCategory) -> Array[VehicleData]:
	var result: Array[VehicleData] = []
	
	for vehicle_data in loaded_vehicles.values():
		if vehicle_data.size_category == size_category:
			result.append(vehicle_data)
	
	return result

func get_vehicle_count() -> int:
	return loaded_vehicles.size()

func is_vehicle_available(vehicle_id: String) -> bool:
	return loaded_vehicles.has(vehicle_id)

# Validation functions
func validate_vehicle_data(vehicle_data: VehicleData) -> Array[String]:
	var errors: Array[String] = []
	
	if vehicle_data.vehicle_id.is_empty():
		errors.append("Vehicle ID is required")
	
	if vehicle_data.display_name.is_empty():
		errors.append("Display name is required")
	
	if vehicle_data.mesh_path.is_empty():
		errors.append("Mesh path is required")
	elif not FileAccess.file_exists(vehicle_data.mesh_path):
		errors.append("Mesh file not found: " + vehicle_data.mesh_path)
	
	if vehicle_data.wheel_positions.size() != 4:
		errors.append("Exactly 4 wheel positions required")
	
	if vehicle_data.collision_size.x <= 0 or vehicle_data.collision_size.y <= 0 or vehicle_data.collision_size.z <= 0:
		errors.append("Collision size must be positive")
	
	return errors

# Debug functions
func print_database_info():
	print("=== Vehicle Database ===")
	print("Total vehicles: ", get_vehicle_count())
	
	for category in vehicle_categories:
		var vehicles = vehicle_categories[category]
		print("Category %s: %d vehicles" % [VehicleData.VehicleType.keys()[category], vehicles.size()])
	
	print("========================")
