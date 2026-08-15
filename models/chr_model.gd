extends Node3D
class_name ChrModel

@export var prop_rotatable :float= 0.0
@export var prop_movable :float= 0.0
@export var prop_cancellable_by_move :bool

@onready var armature :Node3D= %Armature
@onready var anim_player :AnimationPlayer= %AnimationPlayer
@onready var anim_tree :AnimationTree= %AnimationTree
@onready var skeleton_3d :Skeleton3D= %Skeleton3D
var boneid_root :int

func _ready():
	boneid_root = skeleton_3d.find_bone("root")

func get_state_machine() -> AnimationNodeStateMachinePlayback:
	return anim_tree["parameters/playback"]

func get_current_animattion_state() -> StringName:
	var state_machine := get_state_machine()
	return state_machine.get_current_node()

func animation_travel(target: String):
	var state_machine :AnimationNodeStateMachinePlayback= anim_tree["parameters/playback"]
	state_machine.travel(target)

func get_root_motion_position() -> Vector3:
	return armature.global_transform.basis * anim_tree.get_root_motion_position()

func get_root_motion_rotation() -> Quaternion:
	return armature.quaternion * anim_tree.get_root_motion_rotation()
