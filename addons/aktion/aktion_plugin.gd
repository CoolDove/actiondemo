@tool
extends EditorPlugin

var _anim_editor

func _enter_tree():
	_anim_editor = preload("res://addons/aktion/aktion_anim_editor.tscn").instantiate()
	_anim_editor.setup(self)
	add_control_to_dock(DOCK_SLOT_LEFT_BL, _anim_editor)

func _exit_tree():
	remove_control_from_docks(_anim_editor)
	_anim_editor.queue_free()

func _handles(object) -> bool:
	return object is AnimationPlayer

func _edit(object) -> void:
	if object is AnimationPlayer and _anim_editor != null:
		_anim_editor.set_target_player(object)
