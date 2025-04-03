## 
## Project Time v1.00 - Godot 4.x Time Tracker Addon -
## Coded By Gianluca D'Angelo (gregbug@gmail.com)
##
## v1.00 - 30 marzo 2025
## 

@tool
extends Control

## Constants for time calculations and formatting
const RADIUS: int = 6
const SECONDS_PER_DAY: int = 86_400  # Added underscore for readability
const SECONDS_PER_HOUR: int = 3_600
const SECONDS_PER_MINUTE: int = 60
const FORMAT_WITH_DAYS: String = "%dd %02d:%02d:%02d"
const FORMAT_WITHOUT_DAYS: String = "%02d:%02d:%02d"
const DATA_PATH: StringName = "res://project_time.json"
const REPORT_PATH: StringName = "res://project_report.txt"

## Onready variables with explicit type hints
@onready var work_time_panel: PanelContainer = $PanelContainer
@onready var rest_panel: PanelContainer = $PanelContainer/Margin/Layout/RestTime/RestContainer
@onready var additional_panel: PanelContainer = $PanelContainer/Margin/Layout/AdditionalInfo/Container

@onready var project_icon_left: TextureRect = $PanelContainer/Margin/Layout/HBoxContainer/ClockLeft
@onready var project_icon_right: TextureRect = $PanelContainer/Margin/Layout/HBoxContainer/Clockright
@onready var project_label: Label = $PanelContainer/Margin/Layout/Project/ProjectLabel
@onready var project_label_value: Label = $PanelContainer/Margin/Layout/Project/ProjectValue
@onready var project_clear_button: Button = $PanelContainer/Margin/Layout/Project/ClearButton
@onready var project_track_container: VBoxContainer = $PanelContainer/Margin/Layout/ProjectTrackContainer

@onready var session_label: Label = $PanelContainer/Margin/Layout/Session/SessionLabel
@onready var session_label_value: Label = $PanelContainer/Margin/Layout/Session/SessionValue
@onready var session_clear_button: Button = $PanelContainer/Margin/Layout/Session/ClearButton
@onready var session_time_progress: ProgressBar = $PanelContainer/Margin/Layout/Session/ProgressBar

@onready var idle_label: Label = $PanelContainer/Margin/Layout/AdditionalInfo/Container/Margin/Layout/IdleTime/IdleLabel
@onready var idle_label_value: Label = $PanelContainer/Margin/Layout/AdditionalInfo/Container/Margin/Layout/IdleTime/IdleValue
@onready var idle_start_at_label: Label = $PanelContainer/Margin/Layout/AdditionalInfo/Container/Margin/Layout/IdleTimeControl/IdleLabel
@onready var idle_start_at_spin: SpinBox = $PanelContainer/Margin/Layout/AdditionalInfo/Container/Margin/Layout/IdleTimeControl/IdleTime

@onready var external_label: Label = $PanelContainer/Margin/Layout/AdditionalInfo/Container/Margin/Layout/ExternalApp/ExternalLabel
@onready var external_label_value: Label = $PanelContainer/Margin/Layout/AdditionalInfo/Container/Margin/Layout/ExternalApp/ExternalValue

@onready var btn_pause: Button = $PanelContainer/Margin/Layout/Buttons/PauseButton
@onready var btn_resume: Button = $PanelContainer/Margin/Layout/Buttons/ResumeButton

@onready var chk_rest_time: CheckBox = $PanelContainer/Margin/Layout/RestTime/RestContainer/RestTimeMargin/RestLayout/chkRestTime
@onready var rest_bar: ProgressBar = $PanelContainer/Margin/Layout/RestTime/RestContainer/RestTimeMargin/RestLayout/Controls/RestPogressBar
@onready var rest_value: Label = $PanelContainer/Margin/Layout/RestTime/RestContainer/RestTimeMargin/RestLayout/Controls/RestPogressBar/RestValue
@onready var rest_time_spin_box: SpinBox = $PanelContainer/Margin/Layout/RestTime/RestContainer/RestTimeMargin/RestLayout/Controls/RestSpinBox
@onready var rest_icon_left: TextureRect = $PanelContainer/Margin/Layout/RestTime/RestContainer/RestTimeMargin/RestLayout/HBoxContainer/Clockleft
@onready var rest_icon_right: TextureRect = $PanelContainer/Margin/Layout/RestTime/RestContainer/RestTimeMargin/RestLayout/HBoxContainer/Clockright

@onready var rest_dialog: AcceptDialog = $RestDialog
@onready var clear_all_dialog: ConfirmationDialog = $ClearAllDialog
@onready var clear_track_dialog: ConfirmationDialog = $ClearTrackDialog

@onready var report_button: Button = $PanelContainer/Margin/Layout/Report/ReportButton

@onready var timer: Timer = $Timer

@onready var track_scene: PackedScene = preload("res://addons/project_time/widget_working_time/time_tracker.tscn")

## Dictionary that stores all time tracking data with type hint
var _time_sections: Dictionary = {
	"project_time": 0.0,
	"idle_time": 0.0,
	"external_time": 0.0,
	"rest_time_enabled": false,
	"rest_time_value": 15.0,
	"idle_time_out": 5.0,
	"current_screen": "2D",
	"2D": 0.0,
	"3D": 0.0,
	"SCRIPT": 0.0,
	"GAME": 0.0,
	"ASSETLIB": 0.0
}

## All available tracking types with type hint
var track_types: PackedStringArray = ["2D", "3D", "SCRIPT", "GAME", "ASSETLIB"]

## Project data dictionary
var project_data: Dictionary = {}

## Time tracking variables with type hints
var _session_time: float = 0.0
var _project_time: float = 0.0
var _external_time: float = 0.0
var _rest_time_alert: float = 0.0
var _current_track: Node = null
var _idle_timer: Object = null
var _lang: Object = null

var btn_pause_pressed: bool = false
var external_active: bool = false
var track_to_delete: Node = null

func localize(lang: Object) -> void:
	if lang == null:
		return
	_lang = lang
	
	# Localize labels
	project_label.text = lang.translate("PROJECT_TIME")
	session_label.text = lang.translate("SESSION_LABEL")
	idle_label.text = lang.translate("IDLE_LABEL")
	idle_start_at_label.text = lang.translate("IDLE_AFTER_LABEL")
	external_label.text = lang.translate("EXTERNAL_LABEL")
	
	# Localize buttons
	chk_rest_time.text = lang.translate("REST_CHECKBOX")
	report_button.text = lang.translate("REPORT_BUTTON")
	btn_pause.text = lang.translate("PAUSE_BUTTON")
	btn_resume.text = lang.translate("RESUME_BUTTON")
	rest_value.text = lang.translate("REST_LABEL")
	
## Optimized idle status tracking with getter and setter
var _idle_active: bool = false:
	get: return _idle_active
	set(value): _idle_active = value

## Optimized idle seconds tracking with getter and setter
var _idle_seconds: float = 0.0:
	get: return _idle_seconds
	set(value): _idle_seconds = value

## Initialize the project time tracker with improved readability
func _ready() -> void:
	_set_theme()
	_session_time = 0.0
	zero_labels()
	
	var active_track: Node = _current_track
	if not project_data.is_empty() and not project_data.get("data_loaded", false):
		project_data.data_loaded = load_data(_time_sections, DATA_PATH)
		
		_load_time_data()
		_load_tracking_data()
	
	_current_track = active_track
	timer.start()

func _enter_tree() -> void:
	if _idle_timer:
		_idle_timer.stop()
		_idle_timer.wait_time = idle_start_at_spin.value * 60
		_idle_timer.start()

func _exit_tree() -> void:
	_save_time_data()
	save_data(_time_sections, DATA_PATH)

## Reset all time labels to zero
func zero_labels() -> void:
	project_label_value.text = '00:00:00'
	session_label_value.text = '00:00:00'
	idle_label_value.text = '00:00:00'

## Apply the editor theme to all UI elements
func _set_theme() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	
	project_icon_left.modulate = get_theme_color("contrast_color_1", "Editor")
	project_icon_right.modulate = get_theme_color("contrast_color_1", "Editor")
	rest_icon_left.modulate = get_theme_color("contrast_color_1", "Editor")
	rest_icon_right.modulate = get_theme_color("contrast_color_1", "Editor")

	btn_pause.icon = get_theme_icon("Pause", "EditorIcons")
	btn_resume.icon = get_theme_icon("PlayStart", "EditorIcons")
	project_clear_button.icon = get_theme_icon("Remove", "EditorIcons")
	session_clear_button.icon = get_theme_icon("Remove", "EditorIcons")
	report_button.icon = get_theme_icon("AssetLib", "EditorIcons")
	
	_set_label_colors()
	_set_panel_styles()
	
	var fill_style: StyleBoxFlat = rest_bar.get_theme_stylebox("fill").duplicate()
	fill_style.bg_color = get_theme_color("accent_color", "Editor")
	rest_bar.add_theme_stylebox_override("fill", fill_style)

## Set colors for all labels
func _set_label_colors() -> void:
	var accent_color: Color = get_theme_color("accent_color", "Editor")
	var font_color: Color = get_theme_color("font_color", "Editor")
	
	var labels_to_color: Array[Label] = [
		project_label, session_label, idle_label, 
		idle_start_at_label, external_label
	]
	
	var value_labels_to_color: Array[Label] = [
		project_label_value, session_label_value, 
		idle_label_value, external_label_value
	]
	
	for label in labels_to_color:
		label.add_theme_color_override("font_color", accent_color)
	
	for value_label in value_labels_to_color:
		value_label.add_theme_color_override("font_color", font_color)

## Set styles for all panels
func _set_panel_styles() -> void:
	var style_box: StyleBoxFlat = StyleBoxFlat.new()
	style_box.bg_color = get_theme_color("base_color", "Editor")
	style_box.border_color = get_theme_color("contrast_color_1", "Editor")
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = RADIUS
	style_box.corner_radius_top_right = RADIUS
	style_box.corner_radius_bottom_left = RADIUS
	style_box.corner_radius_bottom_right = RADIUS
	
	var panels_to_style: Array[PanelContainer] = [
		work_time_panel, rest_panel, additional_panel
	]
	
	for panel in panels_to_style:
		panel.add_theme_stylebox_override("panel", style_box)

## Optimize file loading with error handling
func load_data(dictionary_to_load: Dictionary, file_path: StringName) -> bool:
	if not FileAccess.file_exists(file_path):
		return save_data(dictionary_to_load, file_path)

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open file: %s. Error: %d" % [file_path, FileAccess.get_open_error()])
		return false
	
	var json_string: String = file.get_as_text()
	file.close()
	
	var parsed_data: Variant = JSON.parse_string(json_string)
	
	if parsed_data == null:
		push_error("JSON Parse Error in file: %s" % file_path)
		return false
	
	if parsed_data is Dictionary:
		dictionary_to_load.clear()
		dictionary_to_load.merge(parsed_data)
		project_data.current_screen = _time_sections.current_screen
		return true
	
	push_error("JSON data is not a Dictionary in file: %s" % file_path)
	return false

## Optimize file saving with robust error handling
func save_data(dictionary_to_save: Dictionary, file_path: StringName) -> bool:
	if project_data.is_empty():
		push_warning("Attempted to save empty project data")
		return false
		
	var json_string: String = JSON.stringify(dictionary_to_save, "  ")
	if json_string.is_empty():
		push_error("Cannot convert dictionary to JSON")
		return false
		
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open file for writing: %s. Error: %d" % [file_path, FileAccess.get_open_error()])
		return false

	file.store_string(json_string)
	file.close()
	
	return true

## Load time data from saved dictionary
func _load_time_data() -> void:
	_project_time = _time_sections.project_time
	_idle_seconds = _time_sections.idle_time
	_external_time = _time_sections.external_time
	
	project_label_value.text = _seconds_to_time(_time_sections.project_time)
	idle_label_value.text = _seconds_to_time(_time_sections.idle_time)
	external_label_value.text = _seconds_to_time(_time_sections.external_time)
	
	chk_rest_time.button_pressed = _time_sections.rest_time_enabled
	rest_time_spin_box.value = _time_sections.rest_time_value
	idle_start_at_spin.value = _time_sections.idle_time_out
	
	_on_chk_rest_time_pressed()

## Load tracking data for each track type
func _load_tracking_data() -> void:
	for type in track_types:
		if _time_sections[type] > 0:
			var track_node: Node = _enable_track(type)
			if track_node:
				track_node.tracker_time_value = _time_sections[type]
				track_node.tracker_time = _seconds_to_time(_time_sections[type])
				track_node._tracker_time_progress.max_value = _project_time
				track_node._tracker_time_progress.value = track_node.tracker_time_value
				track_node.tracker_player_texture = "Pause"

## Save time data to dictionary before saving to file
func _save_time_data() -> void:
	_time_sections.project_time = _project_time
	_time_sections.idle_time = _idle_seconds
	_time_sections.rest_time_enabled = chk_rest_time.button_pressed
	_time_sections.rest_time_value = rest_time_spin_box.value
	_time_sections.idle_time_out = idle_start_at_spin.value	
	_time_sections.external_time = _external_time
	
	for type in track_types:
		var track_node: Node = project_track_container.get_node_or_null(type)
		if track_node:
			_time_sections[type] = track_node.tracker_time_value

	if not project_data.is_empty():
		_time_sections.current_screen = project_data.current_screen

## Enable or get a tracking node for a specific track type
func _enable_track(track_name: String) -> Node:
	if not Engine.is_editor_hint() or not is_inside_tree() or track_name.is_empty():
		_current_track = null
		return null
	
	var track_node: Node = project_track_container.get_node_or_null(track_name.to_upper())

	if track_node:
		if _current_track:
			_current_track.tracker_player_texture = "Pause"
		
		if not btn_pause_pressed:
			track_node.tracker_player_texture = "Play"
			
		_current_track = track_node
		return track_node
		
	var new_track: Node = track_scene.instantiate()
	new_track.name = track_name.to_upper()
	new_track.on_clear_button_pressed.connect(_on_clear_track_requested)
	project_track_container.add_child(new_track)
	new_track.tracker_type = track_name
	new_track.tracker_player_texture = "Play"
	return new_track

## Convert seconds to formatted time string
func _seconds_to_time(seconds: float) -> String:
	var total_seconds: int = int(seconds)
	
	if total_seconds == 0:
		return "00:00:00"
	
	var days: int = total_seconds / SECONDS_PER_DAY
	var remaining: int = total_seconds - (days * SECONDS_PER_DAY)
	var hours: int = remaining / SECONDS_PER_HOUR
	remaining -= hours * SECONDS_PER_HOUR
	
	var minutes: int = remaining / SECONDS_PER_MINUTE
	var secs: int = remaining - (minutes * SECONDS_PER_MINUTE)	
	
	return FORMAT_WITH_DAYS % [days, hours, minutes, secs] if days > 0 else FORMAT_WITHOUT_DAYS % [hours, minutes, secs]

## Timer update method
func _on_timer_timeout() -> void:
	if _idle_active:
		_update_idle_time()
		return
	
	if external_active:
		_update_external_time()
		return
	
	_update_active_time()

## Update time when actively working
func _update_active_time() -> void:
	_project_time += 1
	_session_time += 1
	
	project_label_value.text = _seconds_to_time(_project_time)
	session_label_value.text = _seconds_to_time(_session_time)
	
	_update_progress_bars()
	
	if _current_track:
		_current_track.tracker_time_value += 1
		_current_track.tracker_time = _seconds_to_time(_current_track.tracker_time_value)
	
	_update_track_progress()
	
	if chk_rest_time.button_pressed and !EditorInterface.is_playing_scene():
		_update_rest_time()

## Update progress bars with current values
func _update_progress_bars() -> void:
	session_time_progress.max_value = _project_time
	session_time_progress.value = _session_time

## Update progress for all track types
func _update_track_progress() -> void:
	for type in track_types:
		var track_node: Node = project_track_container.get_node_or_null(type)
		if track_node:
			track_node._tracker_time_progress.max_value = _project_time
			track_node._tracker_time_progress.value = track_node.tracker_time_value

## Update rest time countdown
func _update_rest_time() -> void:
	var rest_time_seconds: float = _rest_time_alert - rest_bar.value
	rest_bar.value += 1
	rest_value.text = _seconds_to_time(rest_time_seconds)
	if rest_time_seconds == 0 and _lang:
		rest_dialog.title = _lang.translate("REST_DIALOG_TITLE")
		rest_dialog.dialog_text = _lang.translate("REST_DIALOG_TEXT")
		rest_dialog.ok_button_text = _lang.translate("REST_OK")
		rest_dialog.popup_centered(rest_dialog.size)
		timer.paused = true

## Update idle time counter
func _update_idle_time() -> void:
	_idle_seconds += 1
	idle_label_value.text = _seconds_to_time(_idle_seconds)

## Update external time counter
func _update_external_time() -> void:
	_external_time += 1
	external_label_value.text = _seconds_to_time(_external_time)

## Pause the timer
func _on_pause_button_pressed() -> void:
	timer.paused = true
	btn_pause.disabled = true
	btn_resume.disabled = false
	btn_pause_pressed = true
	if _lang:
		project_label.text = _lang.translate("PROJECT_PAUSED")
	if _current_track:
		_current_track.tracker_player_texture = "Pause"

## Resume the timer
func _on_resume_button_pressed() -> void:
	timer.paused = false
	btn_pause.disabled = false
	btn_resume.disabled = true
	btn_pause_pressed = false
	if _lang:
		project_label.text = _lang.translate("PROJECT_TIME")
	if _current_track:
		_current_track.tracker_player_texture = "Play"

## Update rest time settings when checkbox is toggled
func _on_chk_rest_time_pressed() -> void:
	if chk_rest_time.button_pressed:
		_rest_time_alert = rest_time_spin_box.value * 60
		rest_value.text = _seconds_to_time(_rest_time_alert)
		rest_bar.max_value = _rest_time_alert
		rest_bar.value = 0
	else:
		if _lang:
			rest_value.text = _lang.translate("REST_LABEL")
		rest_bar.value = 0
	
	_time_sections.rest_time_enabled = chk_rest_time.button_pressed
	_time_sections.rest_time_value = rest_time_spin_box.value

## Update rest time when spin box value changes
func _on_rest_spin_box_value_changed(value: float) -> void:
	_on_chk_rest_time_pressed()

## Handle rest dialog confirmation
func _on_rest_dialog_confirmed() -> void:
	rest_bar.value = 0
	rest_value.text = _seconds_to_time(_rest_time_alert)
	timer.paused = false

## Handle rest dialog cancellation
func _on_rest_dialog_canceled() -> void:
	_on_rest_dialog_confirmed()

## Handle confirmation of clearing all data
func _on_clear_all_dialog_confirmed() -> void:
	_session_time = 0
	_project_time = 0
	_idle_seconds = 0
	_external_time = 0
	rest_bar.value = 0
	_rest_time_alert = rest_time_spin_box.value * 60
	rest_value.text = _seconds_to_time(_rest_time_alert)
	external_label_value.text = _seconds_to_time(_external_time)
	
	_clear_tracks()
	zero_labels()

## Clear all track nodes
func _clear_tracks() -> void:
	for type in track_types:
		var track_node: Node = project_track_container.get_node_or_null(type)
		if track_node:
			_time_sections[type] = 0
			track_node.queue_free()
	_current_track = null

## Handle clear button pressed to show confirmation dialog
func _on_clear_button_pressed() -> void:
	if _lang:
		clear_all_dialog.title = _lang.translate("CLEAR_ALL_TITLE")
		clear_all_dialog.dialog_text = _lang.translate("CLEAR_ALL_TEXT")
		clear_all_dialog.ok_button_text = _lang.translate("BTN_OK")
		clear_all_dialog.cancel_button_text = _lang.translate("BTN_CANCEL")

	clear_all_dialog.popup_centered(clear_all_dialog.size)

## Handle session clear button pressed
func _on_clear_session_button_pressed() -> void:
	track_to_delete = null
	if _lang:
		clear_track_dialog.title = _lang.translate("CLEAR_SESSION_TITLE")
		clear_track_dialog.dialog_text = _lang.translate("CLEAR_SESSION_TEXT")
		clear_track_dialog.ok_button_text = _lang.translate("BTN_OK")
		clear_track_dialog.cancel_button_text = _lang.translate("BTN_CANCEL")
		clear_track_dialog.popup_centered(clear_track_dialog.size)

## Handle session clear confirmation
func _on_clear_session_dialog_confirmed() -> void:
	if track_to_delete == null:
		_session_time = 0
		session_label_value.text = '00:00:00'
	else:
		_project_time -= track_to_delete.tracker_time_value
		if _project_time < 0:
			_project_time = 0
		track_to_delete.queue_free()
		track_to_delete = null

## Handle idle time spinbox value changed
func _on_spin_box_idle_value_changed(value: float) -> void:
	_time_sections.idle_time_out = value
	if _idle_timer:
		_idle_timer.stop()
		_idle_timer.wait_time = value * 60
		_idle_timer.start()

## Handle track clear requested
func _on_clear_track_requested(track_name: String) -> void:
	track_to_delete = _get_track_node(track_name)
	if track_to_delete:
		if _lang:
			clear_track_dialog.title = _lang.translate("CLEAR_TRACK_TITLE")
			clear_track_dialog.dialog_text = _lang.translate("CLEAR_TRACK_TEXT", [track_name])
			clear_track_dialog.ok_button_text = _lang.translate("BTN_OK")
			clear_track_dialog.cancel_button_text = _lang.translate("BTN_CANCEL")
			clear_track_dialog.popup_centered(clear_track_dialog.size)

## Get track node by name
func _get_track_node(track_name: String) -> Node:
	return project_track_container.get_node_or_null(track_name.to_upper())

## Get project name from settings or project file
func _get_project_name() -> String:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return ""
	
	if ProjectSettings.has_setting("application/config/name"):
		var project_name: String = ProjectSettings.get_setting("application/config/name")
		return project_name
	
	var project_file_path: String = "res://project.godot"
	var file: FileAccess = FileAccess.open(project_file_path, FileAccess.READ)
	if not file:
		return ""
	
	var file_contents: String = file.get_as_text()
	file.close()
	
	var regex: RegEx = RegEx.new()
	regex.compile("config/name\\s*=\\s*\"(.+)\"")
	var match: RegExMatch = regex.search(file_contents)
	
	return match.get_string(1) if match else ""

## Get current datetime in a readable format
func _get_readable_datetime() -> String:
	var datetime_dict = Time.get_datetime_dict_from_system()
	var readable_datetime = "%d %s %d at %02d:%02d" % [
		datetime_dict["day"],
		datetime_dict["month"],
		datetime_dict["year"],
		datetime_dict["hour"],
		datetime_dict["minute"]
	]
	
	return readable_datetime

## Calculate percentage with zero division handling
func _calculate_percentage(valore_parziale: float, valore_totale: float) -> float:
	if valore_totale == 0:
		return 0.0

	var percentuale: float = (valore_parziale / valore_totale) * 100.0
	return snappedf(percentuale, 0.01)

## Delete a specific file
func delete_file(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return false
	
	var dir = DirAccess.open("res://")
	if dir:
		var error = dir.remove(file_path)
		if error == OK:
			return true
		else:
			return false
	else:
		return false

## Generate a comprehensive project report
func _generate_report() -> void:	
	var file = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	if file:
		file.store_string('> Project "'+_get_project_name()+'" working time report <\n')
		file.store_string('\n--------------------------------------------------------')

		for type in track_types:
			var track_node: Node = project_track_container.get_node_or_null(type)
			if track_node:
				file.store_string('\n   + %18s' % track_node.tracker_name+': ' +_seconds_to_time(track_node.tracker_time_value)+' (%s%%)' % _calculate_percentage(track_node.tracker_time_value, _project_time));
		
		file.store_string('\n   = %20s' % 'Real Working time: '+_seconds_to_time(_project_time)+' (100%)');
		file.store_string('\n--------------------------------------------------------')
		
		var total_time: float = _project_time + _idle_seconds + _external_time
		
		file.store_string('\n   + %20s' % 'Real Working time: '+_seconds_to_time(_project_time) +' (%s%%)' % _calculate_percentage(_project_time, total_time))
		file.store_string('\n   + %20s' % 'IDLE time: '+_seconds_to_time(_idle_seconds)+' (%s%%)' % _calculate_percentage(_idle_seconds, total_time))
		file.store_string('\n   + %20s' % 'External App time: '+_seconds_to_time(_external_time)+' (%s%%)' % _calculate_percentage(_external_time, total_time))
		file.store_string('\n   = %20s' % 'Total Project time: '+_seconds_to_time(total_time)+' (100%)')
		file.store_string('\n--------------------------------------------------------')
		file.store_string('\n\n > Report generated by Project Time on '+_get_readable_datetime()+' <')

		file.close()
		EditorInterface.get_resource_filesystem().scan()
		OS.shell_open(ProjectSettings.globalize_path(REPORT_PATH))
