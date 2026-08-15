extends Node3D
class_name ChrModel

@onready var armature :Node3D= %Armature
@onready var anim_player :AnimationPlayer= %AnimationPlayer
@onready var anim_tree :AnimationTree= %AnimationTree
@onready var skeleton_3d :Skeleton3D= %Skeleton3D
var boneid_root :int

func _ready():
	boneid_root = skeleton_3d.find_bone("root")

func get_root_motion_position() -> Vector3:
	return armature.global_transform.basis * anim_tree.get_root_motion_position()

func get_root_motion_rotation() -> Quaternion:
	return armature.quaternion * anim_tree.get_root_motion_rotation()
