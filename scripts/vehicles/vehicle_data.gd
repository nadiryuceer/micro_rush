class_name VehicleData
extends Resource

@export var vehicle_id: String
@export var display_name: String
@export var description: String

@export var mesh_path: String
@export var vehicle_type: VehicleType
@export var size_category: SizeCategory

@export var wheel_positions: Array[Vector3]
@export var wheel_size: float = 0.5
@export var collision_size: Vector3 = Vector3(2.0, 1.0, 4.0)

@export var vehicle_stats: VehicleStats

enum VehicleType {
	SPORTS_CAR,
	SEDAN,
	MUSCLE_CAR,
	JEEP,
	SUV,
	TRUCK,
	VAN,
	FIRETRUCK,
	POLICE,
	TAXI,
	TRACTOR,
	RACE_CAR,
	DELIVERY,
	GARBAGE_TRUCK
}

enum SizeCategory {
	SMALL,   # 0.8x scale
	MEDIUM,  # 1.0x scale
	LARGE,   # 1.2x scale
	EXTRA_LARGE  # 1.4x scale
}
