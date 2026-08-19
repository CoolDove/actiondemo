@tool
class_name AnimationTrackFilter
extends VBoxContainer

var _animation: Animation
var _dirty = true

@onready var filter_edit: LineEdit = $FilterEdit
@onready var track_list: VBoxContainer = $ScrollContainer/TrackList
@onready var count_label: Label = $CountLabel

func _ready():
	filter_edit.text_changed.connect(_on_text_changed)

func set_animation(anim: Animation):
	_animation = anim
	_mark_dirty()

func get_filter() -> String:
	return filter_edit.text.strip_edges()

static func matches_path(path: NodePath, filter: String) -> bool:
	if filter.is_empty():
		return true
	var node = str(path).split(':')[0]
	return node == filter or node.begins_with(filter + '/')

func _on_text_changed(_text: String):
	_mark_dirty()

func _process(_delta):
	if _dirty:
		_dirty = false
		_refresh()

func _mark_dirty():
	_dirty = true

func _refresh():
	_clear_list()
	if _animation == null:
		count_label.text = '0 个 track'
		return
	var filter = get_filter()
	var matched = 0
	for i in _animation.get_track_count():
		if matches_path(_animation.track_get_path(i), filter):
			var label = Label.new()
			label.text = str(_animation.track_get_path(i))
			track_list.add_child(label)
			matched += 1
	count_label.text = '%d / %d 个 track' % [matched, _animation.get_track_count()]

func _clear_list():
	for child in track_list.get_children():
		child.free()
