# Base vehicle class for type resolution
# This compiles first and provides the type reference

class_name BaseVehicle
extends CharacterBody3D

# Common vehicle properties that all vehicles will have
var vehicle_data: VehicleData
var wheel_nodes: Array[MeshInstance3D] = []

# Common methods that all vehicles will implement
func setup_from_data(data: VehicleData):
	pass

func update_wheel_visuals(delta: float):
	pass
