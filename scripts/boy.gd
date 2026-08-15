extends CharacterBody3D

@export var mouse_sensitivity = 0.002
@export var rotation_speed = 10.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_anchor = %CameraAnchor

@onready var model: ChrModel = $Model
@onready var anim_tree :AnimationTree= model.anim_tree

var camera_input: Vector2

var camera_pivot: Node3D
var camera: Camera3D

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

func _process(_delta):
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

		var target_direction = (cam_right * input_dir.x + cam_forward * -input_dir.y).normalized()

		if input_dir:
			anim_tree.set("parameters/IdleWalk/blend_position", 1.0)
			rotation.y = lerp_angle(rotation.y, atan2(target_direction.x, target_direction.z), rotation_speed * delta)
		else:
			anim_tree.set("parameters/IdleWalk/blend_position", 0.0)

		var velocity_y := velocity.y
		# if input_dir:
		var root_motion_position :Vector3= model.get_root_motion_position()
		velocity = root_motion_position / delta
		# else:
		# 	velocity = Vector3.ZERO
		velocity.y = velocity_y
		# print("velocity: %s" % [ velocity ])
	move_and_slide()
