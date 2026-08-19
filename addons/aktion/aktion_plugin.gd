@tool
extends EditorPlugin

var _anim_editor
var _animation_editor: Control
var _animation_menu: OptionButton

func _enter_tree():
	_anim_editor = preload("res://addons/aktion/aktion_anim_editor.tscn").instantiate()
	_anim_editor.setup(self)
	add_control_to_dock(DOCK_SLOT_LEFT_BR, _anim_editor)
	_animation_editor = _find_animation_editor()
	_animation_menu = _find_animation_menu()
	if _animation_editor != null:
		_animation_editor.connect("animation_selected", _on_animation_selected)

func _find_animation_editor() -> Control:
	var base = get_editor_interface().get_base_control()
	var matches = base.find_children("*", "AnimationPlayerEditor", true, false)
	if matches.is_empty():
		push_warning("Aktion: 未找到 AnimationPlayerEditor")
		return null
	return matches[0]

func _find_animation_menu() -> OptionButton:
	if _animation_editor == null:
		return null
	# 动画选择下拉是 AnimationPlayerEditor 工具栏里第一个 OptionButton，
	# 其余 OptionButton（插值/时间/easing）都在 AnimationTrackEditor 关键帧编辑面板内，顺序靠后。
	var matches = _animation_editor.find_children("*", "OptionButton", true, false)
	if matches.is_empty():
		push_warning("Aktion: 未找到动画下拉控件")
		return null
	return matches[0]

func get_current_animation() -> String:
	if _animation_menu == null:
		return ""
	var selected = _animation_menu.selected
	if selected < 0 or selected >= _animation_menu.item_count or _animation_menu.is_item_separator(selected):
		return ""
	return _animation_menu.get_item_text(selected)

func _on_animation_selected(name: String):
	if _anim_editor != null:
		_anim_editor.set_target_animation(name)

func push_current_animation():
	if _anim_editor != null:
		_anim_editor.set_target_animation(get_current_animation())

func _exit_tree():
	remove_control_from_docks(_anim_editor)
	_anim_editor.queue_free()

func _handles(object) -> bool:
	return object is AnimationPlayer

func _edit(object) -> void:
	if object is AnimationPlayer and _anim_editor != null:
		_anim_editor.set_target_player(object)
		call_deferred("push_current_animation")
