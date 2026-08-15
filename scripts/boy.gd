extends CharacterBody3D

@export_category("Basic")
@export var mouse_sensitivity := 0.2
@export var rotation_speed := 10.0

@export_category("Move Feeling")
@export var move_startup_time := 0.6
@export var move_stop_time := 0.3

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_anchor = %CameraAnchor
@onready var model: ChrModel = $Model
@onready var anim_tree :AnimationTree= model.anim_tree

var camera_input: Vector2
var move_input: Vector2
var movement_weight := 0.0

var input_attack : bool

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
	move_input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	if !input_attack: input_attack = Input.is_action_just_pressed("attack_light")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if camera_pivot != null:
		camera_pivot.global_rotate(Vector3.UP, camera_input.x * delta)
		camera_pivot.global_rotate(camera_pivot.basis.x, camera_input.y * delta)
		var euler := camera_pivot.global_basis.get_euler(EULER_ORDER_YXZ)
		euler.x = clamp(euler.x, deg_to_rad(-30.0), deg_to_rad(10.0))
		camera_pivot.global_rotation = euler

		var cam_forward = camera_pivot.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()
		var cam_right = camera_pivot.global_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()

		var move_target = 1.0 if move_input else 0.0
		var move_duration = move_startup_time if move_input else move_stop_time
		movement_weight = move_toward(movement_weight, move_target, (1.0 / move_duration) * delta)
		anim_tree.set("parameters/Locomotion/blend_position", movement_weight)

		if move_input:
			var target_direction = (cam_right * move_input.x + cam_forward * -move_input.y).normalized()
			var target_angle := atan2(target_direction.x, target_direction.z)
			rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta * model.prop_rotatable)
			if model.prop_cancellable_by_move && model.get_current_animattion_state() != "Locomotion":
				model.get_state_machine().next()
				print("try move cancel")

		var velocity_y := velocity.y
		var root_motion_position :Vector3= model.get_root_motion_position()
		velocity = root_motion_position / delta
		velocity.y = velocity_y

		if input_attack:
			model.animation_travel("Action")
			input_attack = false
	move_and_slide()
