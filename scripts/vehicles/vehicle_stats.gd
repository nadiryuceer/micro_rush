class_name VehicleStats
extends Resource

@export var max_speed: float = 6.0
@export var acceleration: float = 6.5
@export var steering_speed: float = 3.2
@export var grip: float = 18.0
@export var boost_force: float = 35.0
@export var drag: float = 6.0
@export var weight: float = 1.0  # Affects collision physics

# Size-based stat modifiers
func apply_size_modifier(size: VehicleData.SizeCategory):
	var modifier: float
	match size:
		VehicleData.SizeCategory.SMALL:
			modifier = 0.8
		VehicleData.SizeCategory.MEDIUM:
			modifier = 1.0
		VehicleData.SizeCategory.LARGE:
			modifier = 1.2
		VehicleData.SizeCategory.EXTRA_LARGE:
			modifier = 1.4
		_:
			modifier = 1.0
	
	# Smaller vehicles are faster but less stable
	max_speed *= modifier
	acceleration *= modifier
	grip /= modifier
	weight *= modifier
