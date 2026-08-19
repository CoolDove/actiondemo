@tool
class_name AnimationTrackFilter
extends VBoxContainer

var _animation: Animation
var _dirty = true

@onready var filter_edit: LineEdit = %FilterEdit
@onready var regex_check: CheckBox = %CheckBox_Regex
@onready var case_sensitive_check: CheckBox = %CheckBox_CaseSensitive
@onready var track_list: VBoxContainer = %TrackList
@onready var count_label: Label = %CountLabel

func _ready():
	filter_edit.text_changed.connect(_on_text_changed)
	regex_check.toggled.connect(_on_regex_toggled)
	case_sensitive_check.toggled.connect(_on_case_sensitive_toggled)
	case_sensitive_check.disabled = true

func set_animation(anim: Animation):
	_animation = anim
	_mark_dirty()

func get_filter() -> String:
	return filter_edit.text.strip_edges()

func get_regex() -> bool:
	return regex_check.button_pressed

func get_case_sensitive() -> bool:
	return case_sensitive_check.button_pressed

static func matches_path(path: NodePath, filter: String, regex: bool = false, case_sensitive: bool = false) -> bool:
	if filter.is_empty():
		return true
	if regex:
		var pattern = filter
		if not case_sensitive:
			pattern = '(?i)' + pattern
		var re = RegEx.new()
		if re.compile(pattern) != OK:
			return false
		return re.search(str(path)) != null
	var node = str(path).split(':')[0]
	return node == filter or node.begins_with(filter + '/')

func _on_regex_toggled(pressed: bool):
	if pressed:
		case_sensitive_check.button_pressed = false
	case_sensitive_check.disabled = not pressed
	_mark_dirty()

func _on_case_sensitive_toggled(_pressed: bool):
	_mark_dirty()

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
		count_label.text = '0'
		return
	var filter = get_filter()
	var regex = get_regex()
	var case_sensitive = get_case_sensitive()
	if regex and not filter.is_empty() and not _is_valid_regex(filter, case_sensitive):
		count_label.text = 'Invalid Regex'
		return
	var matched = 0
	for i in _animation.get_track_count():
		if matches_path(_animation.track_get_path(i), filter, regex, case_sensitive):
			var label = Label.new()
			label.text = str(_animation.track_get_path(i))
			track_list.add_child(label)
			matched += 1
	count_label.text = '%d /%d' % [matched, _animation.get_track_count()]

func _is_valid_regex(filter: String, case_sensitive: bool) -> bool:
	var re = RegEx.new()
	return re.compile((filter if case_sensitive else '(?i)' + filter)) == OK

func _clear_list():
	for child in track_list.get_children():
		child.free()
