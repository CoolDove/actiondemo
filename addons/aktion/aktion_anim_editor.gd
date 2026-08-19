@tool
extends VBoxContainer

var editor_plugin: EditorPlugin
var target_player: AnimationPlayer
var target_animation: String = ""
var _last_copied = 0
var _last_deleted = 0
var _dirty = true

@onready var player_label: Label = %PlayerLabel
@onready var source_option: OptionButton = %SourceOption
@onready var source_filter: AnimationTrackFilter = %SourceFilter
@onready var delete_filter: AnimationTrackFilter = %DeleteFilter

func setup(plugin: EditorPlugin):
	editor_plugin = plugin
	%CopyButton.pressed.connect(_on_copy_pressed)
	%OverwriteButton.pressed.connect(_on_overwrite_pressed)
	%DeleteButton.pressed.connect(_on_delete_pressed)
	%SourceOption.item_selected.connect(_on_source_changed)
	_mark_dirty()

func set_target_player(player: AnimationPlayer):
	target_player = player
	_mark_dirty()

func set_target_animation(name: String):
	target_animation = name
	_update_label()
	_update_delete_filter()

func _update_label():
	if target_player == null:
		player_label.text = '未选中 AnimationPlayer'
	elif target_animation.is_empty():
		player_label.text = '目标: ' + target_player.name
	else:
		player_label.text = '目标: ' + target_player.name + ' → ' + target_animation

func _process(_delta):
	if _dirty:
		_dirty = false
		_refresh()

func _mark_dirty():
	_dirty = true

func _refresh():
	if target_player == null:
		_update_label()
		source_option.clear()
		source_filter.set_animation(null)
		delete_filter.set_animation(null)
		return
	_update_label()
	source_option.clear()
	for animation_name in target_player.get_animation_list():
		source_option.add_item(animation_name)
	if source_option.item_count > 0:
		source_option.selected = 0
	_update_source_filter()
	_update_delete_filter()

func _on_source_changed(_index: int):
	_update_source_filter()

func _update_source_filter():
	if target_player == null or source_option.selected < 0:
		source_filter.set_animation(null)
		return
	var name = source_option.get_item_text(source_option.selected)
	source_filter.set_animation(target_player.get_animation(name))

func _update_delete_filter():
	if target_player == null or target_animation.is_empty():
		delete_filter.set_animation(null)
		return
	delete_filter.set_animation(target_player.get_animation(target_animation))

func _get_selected_player() -> AnimationPlayer:
	var selection = editor_plugin.get_editor_interface().get_selection()
	for node in selection.get_selected_nodes():
		if node is AnimationPlayer:
			return node
	return target_player

func _on_copy_pressed():
	_do_copy(false)

func _on_overwrite_pressed():
	_do_copy(true)

func _do_copy(overwrite: bool):
	var player = _get_selected_player()
	if player == null:
		player_label.text = '请先选中场景中的 AnimationPlayer 节点'
		return
	if target_animation.is_empty():
		player_label.text = '请先在动画编辑器中选择目标动画'
		return
	if source_option.selected < 0:
		player_label.text = '没有可用的源动画'
		return
	var source_name = source_option.get_item_text(source_option.selected)
	var target = player.get_animation(target_animation)
	var source = player.get_animation(source_name)
	if target == null or source == null:
		player_label.text = '无法获取动画资源'
		return
	if target == source:
		player_label.text = '源动画与目标动画相同'
		return
	var filter = source_filter.get_filter()
	var regex = source_filter.get_regex()
	var case_sensitive = source_filter.get_case_sensitive()
	var backup = _snapshot_animation(target)
	var undo_redo = editor_plugin.get_undo_redo()
	var verb = '覆盖' if overwrite else '复制'
	undo_redo.create_action(verb + ' Tracks 到 ' + str(target_animation), 0, player)
	undo_redo.add_do_method(self, '_do_copy_tracks', target, source, filter, regex, case_sensitive, overwrite)
	undo_redo.add_undo_method(self, '_restore_animation', target, backup)
	undo_redo.commit_action()
	editor_plugin.get_editor_interface().mark_scene_as_unsaved()
	player_label.text = ('已' + verb + ' %d 个 track') % _last_copied
	_update_delete_filter()
	_refresh_animation_editor(player, target_animation)

func _do_copy_tracks(target: Animation, source: Animation, filter: String, regex: bool, case_sensitive: bool, overwrite: bool):
	if overwrite:
		var paths_to_remove = {}
		for i in source.get_track_count():
			if AnimationTrackFilter.matches_path(source.track_get_path(i), filter, regex, case_sensitive):
				paths_to_remove[source.track_get_path(i)] = true
		for i in range(target.get_track_count() - 1, -1, -1):
			if paths_to_remove.has(target.track_get_path(i)):
				target.remove_track(i)
	var copied = 0
	for i in source.get_track_count():
		if AnimationTrackFilter.matches_path(source.track_get_path(i), filter, regex, case_sensitive):
			source.copy_track(i, target)
			copied += 1
	_last_copied = copied

func _on_delete_pressed():
	var player = _get_selected_player()
	if player == null:
		player_label.text = '请先选中场景中的 AnimationPlayer 节点'
		return
	if target_animation.is_empty():
		player_label.text = '请先在动画编辑器中选择目标动画'
		return
	var target = player.get_animation(target_animation)
	if target == null:
		player_label.text = '无法获取动画资源'
		return
	var filter = delete_filter.get_filter()
	var regex = delete_filter.get_regex()
	var case_sensitive = delete_filter.get_case_sensitive()
	var matched = 0
	for i in target.get_track_count():
		if AnimationTrackFilter.matches_path(target.track_get_path(i), filter, regex, case_sensitive):
			matched += 1
	if matched == 0:
		player_label.text = '没有匹配的 track'
		return
	var backup = _snapshot_animation(target)
	var undo_redo = editor_plugin.get_undo_redo()
	undo_redo.create_action('删除 Tracks 从 ' + str(target_animation), 0, player)
	undo_redo.add_do_method(self, '_do_delete_tracks', target, filter, regex, case_sensitive)
	undo_redo.add_undo_method(self, '_restore_animation', target, backup)
	undo_redo.commit_action()
	editor_plugin.get_editor_interface().mark_scene_as_unsaved()
	player_label.text = '已删除 %d 个 track' % _last_deleted
	_update_delete_filter()
	_refresh_animation_editor(player, target_animation)

func _do_delete_tracks(target: Animation, filter: String, regex: bool, case_sensitive: bool):
	var removed = 0
	for i in range(target.get_track_count() - 1, -1, -1):
		if AnimationTrackFilter.matches_path(target.track_get_path(i), filter, regex, case_sensitive):
			target.remove_track(i)
			removed += 1
	_last_deleted = removed

func _snapshot_animation(anim: Animation) -> Animation:
	var backup = Animation.new()
	for i in anim.get_track_count():
		anim.copy_track(i, backup)
	return backup

func _restore_animation(anim: Animation, backup: Animation):
	while anim.get_track_count() > 0:
		anim.remove_track(anim.get_track_count() - 1)
	for i in backup.get_track_count():
		backup.copy_track(i, anim)

func _refresh_animation_editor(player: AnimationPlayer, anim_name: StringName):
	player.set_current_animation(&'')
	player.set_current_animation(anim_name)
