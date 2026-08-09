extends Node3D

@export var target : Node3D

func _ready():
	var boy = $"../Boy"
	target = boy.camera_anchor
	boy.camera_pivot = self
	boy.camera = $Camera3D

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.002)
		#camera.rotate_x(-event.relative.y * mouse_sensitivity)
		#camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float):
	global_position = target.global_position
