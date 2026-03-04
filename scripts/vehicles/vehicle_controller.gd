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

@export var debug_vehicle_collision := false





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
	
	# GLB collision shapes are used - no manual collision setup needed
	# setup_collision(data.collision_size)
	
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
		if mesh_instance is Node3D:
			print("Initial rotation: ", (mesh_instance as Node3D).rotation_degrees)
			print("Initial position: ", (mesh_instance as Node3D).position)
			print("Initial scale: ", (mesh_instance as Node3D).scale)
		else:
			print("Initial transform: <non-Node3D root>")
		print("=====================================")
		
		# Replace existing CarMesh
		var old_mesh: Node3D = $Visual/CarMesh
		$Visual.remove_child(old_mesh)
		old_mesh.queue_free()
		
		$Visual.add_child(mesh_instance)
		mesh_instance.name = "CarMesh"
		if not copy_glb_collision_from_visual():
			$CollisionShape3D.disabled = true
			$CollisionShape3D.shape = null
			push_error("Vehicle GLB has no collision shapes. Add collision (e.g., convcolonly_...) to the GLB.")
		
		# Show transform after being added to scene tree
		print("=== MESH TRANSFORM (AFTER PARENTING) ===")
		if mesh_instance is Node3D:
			print("Final rotation: ", (mesh_instance as Node3D).rotation_degrees)
			print("Final position: ", (mesh_instance as Node3D).position)
			print("Final scale: ", (mesh_instance as Node3D).scale)
		else:
			print("Final transform: <non-Node3D root>")
		print("=====================================")
		print("Mesh loaded and attached successfully")
	else:
		push_error("Failed to load mesh scene: " + mesh_path)

func copy_glb_collision_from_visual() -> bool:
	var car_mesh: Node = $Visual.get_node_or_null("CarMesh")
	if not car_mesh:
		return false

	var found_shapes: Array[CollisionShape3D] = []
	_collect_collision_shapes(car_mesh, found_shapes)
	if found_shapes.is_empty():
		if debug_vehicle_collision:
			print("[VehicleCollision] No CollisionShape3D found in GLB CarMesh")
		return false

	if debug_vehicle_collision:
		print("[VehicleCollision] Found ", found_shapes.size(), " CollisionShape3D nodes in GLB CarMesh")

	var src: CollisionShape3D = found_shapes[0]
	if not src.shape:
		return false
	if found_shapes.size() > 1:
		push_warning("Vehicle GLB has multiple CollisionShape3D nodes. Only the first one will be used.")
	if debug_vehicle_collision:
		print("[VehicleCollision] Using first shape only")
		print("[VehicleCollision]  src=", src.get_path(),
			" shape=", src.shape.get_class(),
			" src_gt.origin=", src.global_transform.origin,
			" src_gt.basis=", src.global_transform.basis)
		_print_shape_details(src.shape)

	var src_gt := src.global_transform
	var src_scale := src_gt.basis.get_scale()
	var local_xform := global_transform.affine_inverse() * src_gt
	if debug_vehicle_collision:
		print("[VehicleCollision]  src_scale=", src_scale)
		print("[VehicleCollision]  local_xform.origin=", local_xform.origin, " basis=", local_xform.basis)

	var copied_shape: Shape3D = src.shape.duplicate(true)
	if copied_shape is BoxShape3D:
		var box := copied_shape as BoxShape3D
		box.size = Vector3(
			box.size.x * abs(src_scale.x),
			box.size.y * abs(src_scale.y),
			box.size.z * abs(src_scale.z)
		)
		if debug_vehicle_collision:
			print("[VehicleCollision]  baked Box size=", box.size)
	elif copied_shape is SphereShape3D:
		var s := copied_shape as SphereShape3D
		s.radius = s.radius * max(abs(src_scale.x), abs(src_scale.y), abs(src_scale.z))
	elif copied_shape is CapsuleShape3D:
		var c := copied_shape as CapsuleShape3D
		c.radius = c.radius * max(abs(src_scale.x), abs(src_scale.z))
		c.height = c.height * abs(src_scale.y)
	elif copied_shape is CylinderShape3D:
		var cy := copied_shape as CylinderShape3D
		cy.radius = cy.radius * max(abs(src_scale.x), abs(src_scale.z))
		cy.height = cy.height * abs(src_scale.y)

	$CollisionShape3D.shape = copied_shape
	$CollisionShape3D.disabled = false
	$CollisionShape3D.transform = local_xform

	_remove_glb_collision_objects(car_mesh)
	if debug_vehicle_collision:
		print("[VehicleCollision] Copied 1 shape from GLB into CharacterBody3D CollisionShape3D and removed GLB collision objects.")
	return true

func _collect_collision_shapes(node: Node, out: Array[CollisionShape3D]) -> void:
	for child in node.get_children():
		if child is CollisionShape3D:
			out.append(child)
		_collect_collision_shapes(child, out)

func _collect_collision_objects(node: Node, out: Array[CollisionObject3D]) -> void:
	for child in node.get_children():
		if child is CollisionObject3D:
			out.append(child)
		_collect_collision_objects(child, out)

func _remove_glb_collision_objects(car_mesh: Node) -> void:
	var objects: Array[CollisionObject3D] = []
	_collect_collision_objects(car_mesh, objects)
	if debug_vehicle_collision:
		print("[VehicleCollision] Removing ", objects.size(), " CollisionObject3D nodes inside GLB CarMesh")
	for obj in objects:
		(obj as Node).queue_free()
		if debug_vehicle_collision:
			print("[VehicleCollision]  removed obj=", (obj as Node).get_path(), " class=", obj.get_class())

func _print_shape_details(shape: Shape3D) -> void:
	if not debug_vehicle_collision:
		return
	if shape is BoxShape3D:
		print("[VehicleCollision]   Box size=", (shape as BoxShape3D).size)
	elif shape is SphereShape3D:
		print("[VehicleCollision]   Sphere radius=", (shape as SphereShape3D).radius)
	elif shape is CapsuleShape3D:
		print("[VehicleCollision]   Capsule radius=", (shape as CapsuleShape3D).radius, " height=", (shape as CapsuleShape3D).height)
	elif shape is CylinderShape3D:
		print("[VehicleCollision]   Cylinder radius=", (shape as CylinderShape3D).radius, " height=", (shape as CylinderShape3D).height)
	elif shape is ConvexPolygonShape3D:
		var pts := (shape as ConvexPolygonShape3D).points
		print("[VehicleCollision]   Convex points=", pts.size())
	elif shape is ConcavePolygonShape3D:
		var faces := (shape as ConcavePolygonShape3D).data
		print("[VehicleCollision]   Concave face_data_len=", faces.size())
	else:
		print("[VehicleCollision]   Shape type=", shape.get_class())

func generate_box_collision_from_visual() -> void:
	var collision_shape: CollisionShape3D = $CollisionShape3D
	if not collision_shape:
		return

	var car_mesh: Node3D = $Visual.get_node_or_null("CarMesh")
	if not car_mesh:
		return

	var mesh_instances: Array[MeshInstance3D] = []
	_collect_mesh_instances(car_mesh, mesh_instances)
	if mesh_instances.is_empty():
		var fallback := BoxShape3D.new()
		fallback.size = Vector3(1.0, 1.0, 2.0)
		collision_shape.shape = fallback
		collision_shape.position = Vector3(0.0, fallback.size.y * 0.5, 0.0)
		return

	var has_bounds := false
	var min_v := Vector3.ZERO
	var max_v := Vector3.ZERO

	for mi in mesh_instances:
		if not mi.mesh:
			continue
		var aabb := mi.get_aabb()
		var corners := PackedVector3Array([
			Vector3(aabb.position.x, aabb.position.y, aabb.position.z),
			Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z),
			Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z),
			Vector3(aabb.position.x, aabb.position.y, aabb.position.z + aabb.size.z),
			Vector3(aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb.position.z),
			Vector3(aabb.position.x + aabb.size.x, aabb.position.y, aabb.position.z + aabb.size.z),
			Vector3(aabb.position.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb.size.z),
			Vector3(aabb.position.x + aabb.size.x, aabb.position.y + aabb.size.y, aabb.position.z + aabb.size.z),
		])

		for c in corners:
			var world_p := mi.global_transform * c
			var local_p := to_local(world_p)
			if not has_bounds:
				min_v = local_p
				max_v = local_p
				has_bounds = true
			else:
				min_v = min_v.min(local_p)
				max_v = max_v.max(local_p)

	if not has_bounds:
		return

	var size := max_v - min_v
	size.x = max(size.x, 0.05)
	size.y = max(size.y, 0.05)
	size.z = max(size.z, 0.05)

	var center := (min_v + max_v) * 0.5
	var box := BoxShape3D.new()
	box.size = size
	collision_shape.shape = box
	collision_shape.position = center

func _collect_mesh_instances(node: Node, out: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			out.append(child)
		_collect_mesh_instances(child, out)

func setup_collision(collision_size: Vector3):
	var collision_shape = $CollisionShape3D
	if collision_shape and collision_shape.shape is BoxShape3D:
		collision_shape.shape.size = collision_size
		# Adjust collision position
		collision_shape.position.y = collision_size.y * 0.5

func setup_wheels():
	# Use existing GLB wheels directly but calculate their center of volume
	wheel_nodes.clear()
	
	# Find existing wheel nodes in the loaded mesh
	var visual_node = $Visual
	if visual_node:
		find_existing_wheels(visual_node)
	
	print("Found ", wheel_nodes.size(), " existing wheel nodes in mesh")
	for wheel in wheel_nodes:
		var pos_type = "Front" if "front" in wheel.name.to_lower() else "Rear"
		print("  ", pos_type, " wheel: ", wheel.name, " at ", wheel.position)
		
		# Calculate and store the wheel's center of volume
		var wheel_center = Vector3.ZERO
		if wheel.mesh:
			var aabb = wheel.mesh.get_aabb()
			wheel_center = aabb.position + aabb.size * 0.5
			print("  Wheel mesh bounds: ", aabb)
			print("  Calculated wheel center: ", wheel_center)
		
		# Store the center for rotation calculations
		wheel_original_rotations[wheel] = wheel_center

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
			# Get the stored wheel center
			var wheel_center = wheel_original_rotations.get(wheel, Vector3.ZERO)
			
			# Create rotation around the wheel's center of volume
			# Transform approach: translate to origin, rotate, translate back
			var rotation_transform = Transform3D()
			rotation_transform = rotation_transform.translated(-wheel_center)
			rotation_transform = rotation_transform.rotated(Vector3.UP, deg_to_rad(steering_angle_deg))
			rotation_transform = rotation_transform.translated(wheel_center)
			
			# Apply the transform to the wheel
			wheel.transform = rotation_transform
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
