extends BaseVehicle

class_name VehicleController

# Physics parameters (loaded from vehicle_data)
@export var acceleration := 6.5
@export var max_speed := 6
@export var steering_speed := 3.2
@export var grip := 18.0
@export var boost_force := 35.0
@export var drag := 6.0

@export var steering_drag := 2.2
@export var steering_drag_boosted := 1.2

# Store original wheel rotations from GLB
var wheel_original_rotations: Dictionary = {}

@export var wall_speed_loss := 0.85   # NEW: how hard walls kill speed
@export var min_stop_speed := 0.6     # NEW: snap to zero below this

@export var boost_max_speed := 8.5
@export var boost_acceleration := 14.0
@export var boost_steering_multiplier := 0.35

var boosting := false

@export var controllable := true
@export var can_be_eliminated := true

var current_speed := 0.0
var steering_input := 0.0
var throttle := 0.0

@onready var warning_node := $Warning/Sprite3D

@export var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var vertical_velocity := 0.0

@export var align_speed := 8.0

@export var air_steering_multiplier := 0.25

# Wheel rotation parameters
@export var wheel_rotation_multiplier := 2.0
@export var max_steering_angle := 30.0  # degrees





func _physics_process(delta: float) -> void:
	if not controllable:
		return

	handle_input(delta)
	apply_movement(delta)
	velocity.y = vertical_velocity
	move_and_slide()
	align_to_floor(delta)
	update_wheel_visuals(delta)

	vertical_velocity = velocity.y

	handle_wall_collisions()

# Data-driven setup
func setup_from_data(data: VehicleData):
	vehicle_data = data
	
	# Load physics stats
	if data.vehicle_stats:
		acceleration = data.vehicle_stats.acceleration
		max_speed = data.vehicle_stats.max_speed
		steering_speed = data.vehicle_stats.steering_speed
		grip = data.vehicle_stats.grip
		boost_force = data.vehicle_stats.boost_force
		drag = data.vehicle_stats.drag
	else:
		push_error("Vehicle stats not found for: " + data.display_name)
	
	# Load visual mesh
	load_vehicle_mesh(data.mesh_path)
	
	# Setup collision
	setup_collision(data.collision_size)
	
	# Setup wheels
	setup_wheels()

func load_vehicle_mesh(mesh_path: String):
	print("Loading vehicle mesh from: ", mesh_path)
	if not FileAccess.file_exists(mesh_path):
		push_error("Vehicle mesh not found: " + mesh_path)
		return
	
	var mesh_scene = load(mesh_path)
	if mesh_scene:
		var mesh_instance = mesh_scene.instantiate()
		print("Mesh instance created: ", mesh_instance.get_class())
		
		# Show mesh transform immediately after instantiation
		print("=== MESH TRANSFORM (CODE LOADED) ===")
		print("Initial rotation: ", mesh_instance.rotation_degrees)
		print("Initial position: ", mesh_instance.position)
		print("Initial scale: ", mesh_instance.scale)
		print("=====================================")
		
		# Replace existing CarMesh
		var old_mesh = $Visual/CarMesh
		$Visual.remove_child(old_mesh)
		old_mesh.queue_free()
		
		$Visual.add_child(mesh_instance)
		mesh_instance.name = "CarMesh"
		
		# Show transform after being added to scene tree
		print("=== MESH TRANSFORM (AFTER PARENTING) ===")
		print("Final rotation: ", mesh_instance.rotation_degrees)
		print("Final position: ", mesh_instance.position)
		print("Final scale: ", mesh_instance.scale)
		print("=====================================")
		print("Mesh loaded and attached successfully")
	else:
		push_error("Failed to load mesh scene: " + mesh_path)

func setup_collision(collision_size: Vector3):
	var collision_shape = $CollisionShape3D
	if collision_shape and collision_shape.shape is BoxShape3D:
		collision_shape.shape.size = collision_size
		# Adjust collision position
		collision_shape.position.y = collision_size.y * 0.5

func setup_wheels():
	# Don't create custom wheels - use existing wheels from GLB mesh
	wheel_nodes.clear()
	
	# Find existing wheel nodes in the loaded mesh
	var visual_node = $Visual
	if visual_node:
		find_existing_wheels(visual_node)
	
	print("Found ", wheel_nodes.size(), " existing wheel nodes in mesh")
	for wheel in wheel_nodes:
		var pos_type = "Front" if "front" in wheel.name.to_lower() else "Rear"
		print("  ", pos_type, " wheel: ", wheel.name, " at ", wheel.position)

func find_existing_wheels(node: Node):
	# Recursively search for wheel nodes in the mesh hierarchy
	for child in node.get_children():
		# Check if this node is a wheel based on naming convention
		if child is MeshInstance3D and "wheel" in child.name.to_lower():
			# Show detailed info for all wheel nodes
			print("=== WHEEL NODE FOUND ===")
			print("Name: ", child.name)
			print("Position: ", child.position)
			print("Rotation: ", child.rotation_degrees)
			print("Scale: ", child.scale)
			print("Parent: ", child.get_parent().name)
			print("Is Front: ", "front" in child.name.to_lower())
			print("========================")
			
			# Store original rotation from GLB
			wheel_original_rotations[child] = child.rotation.y
			
			# Separate front and rear wheels by name
			if "front" in child.name.to_lower():
				wheel_nodes.append(child)  # Add front wheels first
				print("→ Classified as FRONT wheel")
			elif "rear" in child.name.to_lower() or "back" in child.name.to_lower():
				wheel_nodes.append(child)  # Add rear wheels after
				print("→ Classified as REAR wheel")
			else:
				print("→ WARNING: Wheel node doesn't specify front/rear!")
		
		# Recursively check children
		find_existing_wheels(child)

func update_wheel_visuals(delta: float):
	if wheel_nodes.size() == 0:
		return
	
	# Steering angle based on user input
	var steering_angle_deg = steering_input * max_steering_angle
	
	# Apply steering to front wheels only (based on their names)
	for wheel in wheel_nodes:
		if "front" in wheel.name.to_lower():
			# Get the original rotation from GLB (stored during setup)
			var original_rotation = wheel_original_rotations.get(wheel, 0.0)
			# Apply steering relative to original GLB rotation
			wheel.rotation.y = original_rotation + deg_to_rad(steering_angle_deg)
		# Rear wheels: don't touch their rotation at all


# ---------------- INPUT ----------------

func handle_input(delta: float) -> void:
	var accel_input := (
		Input.get_action_strength("accelerate")
		- Input.get_action_strength("brake")
	)

	throttle = accel_input

	steering_input = (
		Input.get_action_strength("steer_left")
		- Input.get_action_strength("steer_right")
	)

	boosting = Input.is_action_pressed("boost") and abs(current_speed) > 2.0
	if not is_on_floor():
		boosting = false


	# --- SPEED CONTROL ---
	if boosting:
		current_speed = move_toward(
			current_speed,
			boost_max_speed * sign(current_speed if current_speed != 0 else 1.0),
			boost_acceleration * delta
		)
	else:
		current_speed += accel_input * acceleration * delta
		current_speed = clamp(current_speed, -max_speed * 0.5, max_speed)

	# Strong drag when no throttle
	if abs(throttle) < 0.05 and not boosting:
		current_speed = move_toward(current_speed, 0.0, drag * delta)
	
	# --- SPEED LOSS FROM HARD STEERING ---
	if is_on_floor() and abs(throttle) > 0.05:
		var steer_amount : float = abs(steering_input)

		if steer_amount > 0.1:
			var drag_strength := steering_drag_boosted if boosting else steering_drag

			# Scale loss by speed (no loss at very low speed)
			var speed_factor : float = clamp(abs(current_speed) / max_speed, 0.0, 1.0)

			current_speed = move_toward(
				current_speed,
				0.0,
				steer_amount * drag_strength * speed_factor * delta
			)




# ---------------- MOVEMENT ----------------

func apply_movement(delta: float) -> void:
	var on_floor := is_on_floor()

	# Gravity
	if not on_floor:
		vertical_velocity -= gravity * delta
	else:
		if vertical_velocity < 0.0:
			vertical_velocity = 0.0

	var steer_multiplier := 1.0

	if boosting:
		steer_multiplier = boost_steering_multiplier
	elif not is_on_floor():
		steer_multiplier = air_steering_multiplier

	var speed_ratio : float = abs(current_speed) / max_speed
	var steer_dir : float = sign(current_speed)
	rotation.y += (
		steering_input
		* steering_speed
		* steer_multiplier
		* delta
		* speed_ratio
		* steer_dir
	)


	# Forward direction
	var forward := -transform.basis.z.normalized()

	# Target forward velocity ONLY
	var target_forward := forward * current_speed

	# Strong lateral damping (MMV4 feel)
	var lateral := velocity - velocity.project(forward)
	lateral.y = 0.0

	var lateral_grip := grip

	if boosting:
		lateral_grip *= 8.0
	elif not is_on_floor():
		lateral_grip *= 0.4

	lateral = lateral.move_toward(Vector3.ZERO, lateral_grip * delta)



	# Combine
	velocity.x = target_forward.x
	velocity.z = target_forward.z

	# Apply minimal lateral correction (optional, feels good)
	velocity.x += lateral.x
	velocity.z += lateral.z

	# Hard speed cap
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	if horizontal.length() > max_speed:
		horizontal = horizontal.normalized() * max_speed
		velocity.x = horizontal.x
		velocity.z = horizontal.z





# ---------------- COLLISIONS ----------------

func handle_wall_collisions() -> void:
	if get_slide_collision_count() == 0:
		return

	var forward := -transform.basis.z.normalized()

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()

		# Detect frontal impact
		var frontal_hit := normal.dot(forward) < -0.5

		if frontal_hit:
			# Kill stored speed
			current_speed *= (1.0 - wall_speed_loss)

			# Prevent rebound acceleration
			velocity = velocity.slide(normal)

			# Snap to full stop if slow enough
			if abs(current_speed) < min_stop_speed:
				current_speed = 0.0
				velocity = Vector3.ZERO


# ---------------- WARNINGS ----------------

func show_warning() -> void:
	if warning_node:
		warning_node.visible = true


func hide_warning() -> void:
	if warning_node:
		warning_node.visible = false


func align_to_floor(delta: float) -> void:
	if not is_on_floor():
		return

	var normal := get_floor_normal()

	# Desired orientation: forward stays forward, up matches floor
	var forward := -transform.basis.z
	var right := forward.cross(normal).normalized()
	forward = normal.cross(right).normalized()

	var target_basis := Basis(right, normal, -forward)

	$Visual.global_transform.basis = (
		$Visual.global_transform.basis
		.slerp(target_basis, align_speed * delta)
	)
