@tool
extends VBoxContainer

var editor_plugin: EditorPlugin
var target_player: AnimationPlayer
var _last_copied = 0

@onready var player_label: Label = %PlayerLabel
@onready var target_option: OptionButton = %TargetOption
@onready var source_option: OptionButton = %SourceOption
@onready var node_path_edit: LineEdit = %NodePathEdit
@onready var status_label: Label = %StatusLabel

func setup(plugin: EditorPlugin):
	editor_plugin = plugin
	%CopyButton.pressed.connect(_on_copy_pressed)
	_refresh()

func set_target_player(player: AnimationPlayer):
	target_player = player
	_refresh()

func _refresh():
	if target_player == null:
		player_label.text = '未选中 AnimationPlayer'
		target_option.clear()
		source_option.clear()
		return
	player_label.text = '目标: ' + target_player.name
	target_option.clear()
	source_option.clear()
	for animation_name in target_player.get_animation_list():
		target_option.add_item(animation_name)
		source_option.add_item(animation_name)

func _get_selected_player() -> AnimationPlayer:
	var selection = editor_plugin.get_editor_interface().get_selection()
	for node in selection.get_selected_nodes():
		if node is AnimationPlayer:
			return node
	return target_player

func _on_copy_pressed():
	var player = _get_selected_player()
	if player == null:
		status_label.text = '请先选中场景中的 AnimationPlayer 节点'
		return
	if target_option.selected < 0:
		status_label.text = '没有可用的目标动画'
		return
	var target_name = target_option.get_item_text(target_option.selected)
	if source_option.selected < 0:
		status_label.text = '没有可用的源动画'
		return
	var source_name = source_option.get_item_text(source_option.selected)
	var target = player.get_animation(target_name)
	var source = player.get_animation(source_name)
	if target == null or source == null:
		status_label.text = '无法获取动画资源'
		return
	if target == source:
		status_label.text = '源动画与目标动画相同'
		return
	var filter = node_path_edit.text.strip_edges()
	var start = target.get_track_count()
	var undo_redo = editor_plugin.get_undo_redo()
	undo_redo.create_action('复制 Tracks 到 ' + str(target_name), 0, player)
	undo_redo.add_do_method(self, '_do_copy_tracks', target, source, filter)
	undo_redo.add_undo_method(self, '_undo_copy_tracks', target, start)
	undo_redo.commit_action()
	editor_plugin.get_editor_interface().mark_scene_as_unsaved()
	status_label.text = '已复制 %d 个 track' % _last_copied
	_refresh_animation_editor(player, target_name)

func _do_copy_tracks(target: Animation, source: Animation, filter: String):
	var copied = 0
	for i in source.get_track_count():
		if _track_matches(source.track_get_path(i), filter):
			source.copy_track(i, target)
			copied += 1
	_last_copied = copied

func _undo_copy_tracks(target: Animation, start: int):
	while target.get_track_count() > start:
		target.remove_track(target.get_track_count() - 1)

func _track_matches(path: NodePath, filter: String) -> bool:
	if filter.is_empty():
		return true
	var node = str(path).split(':')[0]
	return node == filter or node.begins_with(filter + '/')

func _refresh_animation_editor(player: AnimationPlayer, anim_name: StringName):
	player.set_current_animation(&'')
	player.set_current_animation(anim_name)
