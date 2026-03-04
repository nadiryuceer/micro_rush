class_name GameManager
extends Node

# Main game manager that coordinates all systems
signal game_ready()
signal vehicle_spawned(vehicle: BaseVehicle)

var vehicle_database: VehicleDatabase
var current_vehicles: Array[BaseVehicle] = []

func _ready():
	setup_vehicle_system()
	test_data_driven_vehicles()

func setup_vehicle_system():
	vehicle_database = VehicleDatabase.new()
	add_child(vehicle_database)
	
	# Wait for database to load
	vehicle_database.database_loaded.connect(_on_database_loaded)

func _on_database_loaded():
	print("Vehicle database loaded with ", vehicle_database.get_vehicle_count(), " vehicles")
	game_ready.emit()

func test_data_driven_vehicles():
	# Test loading the ambulance vehicle
	var ambulance_data = VehicleFactory.load_vehicle_data("ambulance")
	if ambulance_data:
		print("Successfully loaded ambulance: ", ambulance_data.display_name)
		
		# Create a vehicle instance
		var vehicle = VehicleFactory.create_vehicle(ambulance_data)
		if vehicle:
			add_child(vehicle)
			vehicle.global_position = Vector3(0, 1, 0)
			print("Vehicle spawned at position: ", vehicle.global_position)
			
			# Add vehicle to camera's players array
			var camera_rig = get_node("CameraRig")
			if camera_rig:
				camera_rig.players.append(vehicle)
				print("Vehicle added to camera follow list")
			
			current_vehicles.append(vehicle)
			vehicle_spawned.emit(vehicle)
			
			print("Created vehicle with stats:")
			print("  Max Speed: ", vehicle.max_speed)
			print("  Acceleration: ", vehicle.acceleration)
			print("  Grip: ", vehicle.grip)
	else:
		print("Failed to load ambulance data")

func spawn_vehicle(vehicle_id: String, position: Vector3 = Vector3.ZERO) -> BaseVehicle:
	var vehicle_data = vehicle_database.get_vehicle(vehicle_id)
	if not vehicle_data:
		push_error("Vehicle not found: " + vehicle_id)
		return null
	
	var vehicle = VehicleFactory.create_vehicle(vehicle_data)
	if vehicle:
		add_child(vehicle)
		vehicle.global_position = position
		current_vehicles.append(vehicle)
		vehicle_spawned.emit(vehicle)
	
	return vehicle

func spawn_random_vehicles(count: int, spawn_area: Vector3 = Vector3(10, 0, 10)):
	for i in range(count):
		var vehicle_data = vehicle_database.get_random_vehicle()
		if vehicle_data:
			var position = Vector3(
				randf_range(-spawn_area.x, spawn_area.x),
				1.0,
				randf_range(-spawn_area.z, spawn_area.z)
			)
			spawn_vehicle(vehicle_data.vehicle_id, position)

func get_vehicles_by_type(vehicle_type: VehicleData.VehicleType) -> Array[BaseVehicle]:
	var result: Array[BaseVehicle] = []
	for vehicle in current_vehicles:
		if vehicle.vehicle_data and vehicle.vehicle_data.vehicle_type == vehicle_type:
			result.append(vehicle)
	return result

func clear_vehicles():
	for vehicle in current_vehicles:
		vehicle.queue_free()
	current_vehicles.clear()
