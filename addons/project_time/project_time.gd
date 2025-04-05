## 
## Project Time v1.00 - Godot 4.x Time Tracker Addon -
## Coded By Gianluca D'Angelo (gregbug@gmail.com)
##
## v1.00 - 30 marzo 2025
## 

@tool
extends EditorPlugin

## Constants for widget and dock paths
const WORKING_TIME_WIDGET: String = "res://addons/project_time/widget_working_time/working_time.tscn"
const CLOCK_WIDGET: String = "res://addons/project_time/widget_clock/clock.tscn"
const EDITOR_DOCK: int = EditorPlugin.CONTAINER_TOOLBAR

var translation_manager = null
var idle_timeout: float = 300.0

## Tracks the current editor screen/viewport
var _current_screen: String = "2D"

## Timers for managing plugin functionality
var _idle_timer: Timer = null
var _project_loop_timer: Timer = null

## Widget instances
var _clock_widget_instance: Node = null
var _working_time_instance: Control = null

## Project tracking data dictionary
var _project_data: Dictionary = {
	"data_loaded": false,
	"current_screen": "2D"
}

## Flag to manage scene play state tracking
var _pause_for_play: bool = false

## Initialize working time instance idle timer connection
func _ready() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		if _working_time_instance and _idle_timer:
			_working_time_instance._idle_timer = _idle_timer
			_working_time_instance.localize(translation_manager)

## Plugin entry point: Set up all necessary components
func _enter_tree() -> void:
	# Reset project data
	_project_data.data_loaded = false
	_project_data.idle_timeout = idle_timeout
 
	# Ensure we're in the editor context
	if Engine.is_editor_hint() and is_inside_tree():
		translation_manager = preload("res://addons/project_time/helpers/translation_manager.gd").new()
		translation_manager.init()
		
		_setup_widgets()
		_schedule_initial_tab_switch()
		_setup_timers()

## Set up project timers
func _setup_timers() -> void:
	_enable_project_loop_timer()
	_enable_idle_timer()

## Set up editor widgets
func _setup_widgets() -> void:
	_enable_clock_widget()
	_enable_working_time_widget()

## Schedule a delayed tab switch to ensure editor is fully loaded
func _schedule_initial_tab_switch() -> void:
	var late_call := Timer.new()
	late_call.wait_time = 0.25  # Brief delay to ensure editor readiness
	late_call.one_shot = true
	late_call.ignore_time_scale = true
	late_call.timeout.connect(_switch_to_tab)
	add_child(late_call)
	late_call.start()

## Switch to the last used editor tab
func _switch_to_tab() -> void:
	main_screen_changed.connect(_on_main_screen_changed)

	if _working_time_instance and _working_time_instance.project_data.data_loaded:
		_current_screen = _working_time_instance.project_data.current_screen
		_project_data.current_screen = _current_screen

## Track and update current screen when changed
func _on_main_screen_changed(screen_name: String) -> void:
	_current_screen = screen_name
	_project_data.current_screen = _current_screen
	
	if _working_time_instance:
		_working_time_instance.project_data.current_screen = _current_screen

## Clean up plugin resources when exiting
func _exit_tree() -> void:
	if Engine.is_editor_hint() and is_inside_tree():
		main_screen_changed.disconnect(_on_main_screen_changed)
		_disable_project_loop_timer()
		_disable_working_time_widget()
		_disable_clock_widget()
		_disable_idle_timer()

## Create and start project loop timer
func _enable_project_loop_timer() -> void:
	if _project_loop_timer:
		return  # Already enabled
	
	_project_loop_timer = Timer.new()
	_project_loop_timer.wait_time = 1.0
	_project_loop_timer.autostart = true
	_project_loop_timer.one_shot = false
	_project_loop_timer.ignore_time_scale = true
	_project_loop_timer.timeout.connect(_on_project_timer_timeout)
	add_child(_project_loop_timer)
	_project_loop_timer.start()

## Disable and clean up project loop timer
func _disable_project_loop_timer() -> void:
	if not _project_loop_timer:
		return  # Already disabled
	
	_project_loop_timer.timeout.disconnect(_on_project_timer_timeout)
	_project_loop_timer.queue_free()
	_project_loop_timer = null

## Create and start idle timer
func _enable_idle_timer() -> void:
	if _idle_timer:
		return  # Already enabled
	
	_idle_timer = Timer.new()
	_idle_timer.wait_time = idle_timeout
	_idle_timer.autostart = false
	_idle_timer.one_shot = true
	_idle_timer.ignore_time_scale = true
	_idle_timer.timeout.connect(_on_timer_idle_timeout)
	add_child(_idle_timer)
	_idle_timer.start()

## Disable and clean up idle timer
func _disable_idle_timer() -> void:
	if not _idle_timer:
		return  # Already disabled
	
	_idle_timer.timeout.disconnect(_on_timer_idle_timeout)
	_idle_timer.queue_free()
	_idle_timer = null

## Create and add clock widget to editor
func _enable_clock_widget() -> void:
	if _clock_widget_instance:
		return  # Already enabled
	
	var clock_widget_scene: PackedScene = load(CLOCK_WIDGET)
	if clock_widget_scene:
		_clock_widget_instance = clock_widget_scene.instantiate()
		add_control_to_container(EDITOR_DOCK, _clock_widget_instance)
	else:
		push_error("Failed to load clock widget scene: " + CLOCK_WIDGET)

## Remove and clean up clock widget
func _disable_clock_widget() -> void:
	if not _clock_widget_instance:
		return  # Already disabled
	
	remove_control_from_container(EDITOR_DOCK, _clock_widget_instance)
	_clock_widget_instance.queue_free()
	_clock_widget_instance = null

## Create and add working time widget to editor dock
func _enable_working_time_widget() -> void:
	if _working_time_instance:
		return  # Already enabled
	
	var working_time_scene: PackedScene = preload(WORKING_TIME_WIDGET)
	if working_time_scene:
		_working_time_instance = working_time_scene.instantiate()
		_working_time_instance.name = "Project Time"
		_working_time_instance.project_data = _project_data.duplicate()
		_working_time_instance.project_data.data_loaded = false
		
		add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, _working_time_instance)
	else:
		push_error("Failed to load working time widget scene: " + WORKING_TIME_WIDGET)

## Remove and clean up working time widget
func _disable_working_time_widget() -> void:
	if not _working_time_instance:
		return  # Already disabled
	
	remove_control_from_docks(_working_time_instance)
	_working_time_instance.queue_free()
	_working_time_instance = null

## Handle idle timeout: Mark working time as idle if no external activity
func _on_timer_idle_timeout() -> void:
	if is_instance_valid(_working_time_instance):
		if not _working_time_instance.external_active:
			_working_time_instance._idle_active = true

## Track input events to reset idle timer and manage external activity
func _input(event: InputEvent) -> void:
	if event and is_instance_valid(_working_time_instance):
		for window_id in DisplayServer.get_window_list():
			if DisplayServer.window_is_focused(window_id):
				_working_time_instance._idle_active = false
				_working_time_instance.external_active = false
				_idle_timer.start()

## Periodic project timer timeout handler for tracking project state
func _on_project_timer_timeout() -> void:
	if !is_instance_valid(_working_time_instance):
		return

	# Handle scene play state
	if EditorInterface.is_playing_scene():
		_working_time_instance.external_active = false
		_working_time_instance._enable_track("Game")
		if not _working_time_instance.btn_pause_pressed:
			_working_time_instance.timer.paused = false
		return
	
	# Check window focus and update tracking
	for window_id in DisplayServer.get_window_list():
		if DisplayServer.window_is_focused(window_id):
			_working_time_instance.external_active = false
			
			if _current_screen != "Game":
				if not _working_time_instance.btn_pause_pressed:
					if _pause_for_play:
						_working_time_instance.timer.paused = false
						_pause_for_play = false
				_working_time_instance._enable_track(_current_screen)
			else:
				if not _working_time_instance.btn_pause_pressed:
					_pause_for_play = true
					_working_time_instance.timer.paused = true
					if _working_time_instance._current_track:
						_working_time_instance._current_track.tracker_player_texture = "Pause"
			return
	
	# Handle external activity
	if not _working_time_instance._idle_active:
		_working_time_instance.external_active = true
