extends Node3D

@export var target : Node3D

func _ready():
	await get_tree().process_frame
	var boy = $"../Boy"
	target = boy.camera_anchor
	boy.camera_pivot = self
	boy.camera = $Camera3D

func _process(delta: float):
	if target == null:
		return
	global_position = target.global_position
