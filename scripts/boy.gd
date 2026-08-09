extends CharacterBody3D

@export var speed = 5.0
@export var mouse_sensitivity = 0.002
@export var rotation_speed = 10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_anchor = %CameraAnchor

var camera_input : Vector2

#< Should be initialized outside
var camera_pivot : Node3D
var camera : Camera3D
#>

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if camera == null:
		return
	if event is InputEventMouseMotion:
		var horizontal :float= -event.relative.x * mouse_sensitivity
		var vertical   :float= -event.relative.y * mouse_sensitivity
		camera_input = Vector2(horizontal, vertical)
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta):
	camera_input = Vector2.ZERO

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if camera_pivot != null:
		var mouse_sens := 100.0
		camera_pivot.global_rotate(Vector3.UP, camera_input.x * mouse_sens * delta)
		camera_pivot.global_rotate(camera_pivot.basis.x, camera_input.y * mouse_sens * delta)
		var euler := camera_pivot.global_basis.get_euler(EULER_ORDER_YXZ)
		euler.x = clamp(euler.x, deg_to_rad(-30.0), deg_to_rad(30.0))
		camera_pivot.global_rotation = euler
		
		var input_dir = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		var cam_forward = camera_pivot.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		var cam_right = camera_pivot.global_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()
		var chr_forward = global_transform.basis.z

		var target_direction = (cam_right * input_dir.x + cam_forward * -input_dir.y).normalized()
		if input_dir:
			velocity.x = chr_forward.x * speed
			velocity.z = chr_forward.z * speed
			rotation.y = lerp_angle(rotation.y, atan2(target_direction.x, target_direction.z), rotation_speed * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	move_and_slide()
