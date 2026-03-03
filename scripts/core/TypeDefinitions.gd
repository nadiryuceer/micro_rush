# Global type definitions for compilation order
# This will be autoloaded and available everywhere

extends Node

# Forward declaration class for VehicleController
class VehicleControllerRef:
	pass

# Type alias for better readability
typedef VehicleArray = Array[VehicleController]
