## 
## Project Time v1.00 - Godot 4.x Time Tracker Addon
## Coded By Gianluca D'Angelo (gregbug@gmail.com)
## 
## v1.00 - March 30, 2025
## 

@tool
extends VBoxContainer

## Emitted when clear button is pressed
signal on_clear_button_pressed(section_name)

@onready var _tracker_icon: TextureRect = %TrackerIcon
@onready var _player_icon: TextureRect = %PlayerIcon
@onready var _tracker_label: Label = %TrackerLabel
@onready var _tracker_time_label: Label = %TrackerTimeLabel
@onready var _tracker_button: Button = %TrackerButton
@onready var _tracker_panel_container: PanelContainer = %PanelContainer
@onready var _tracker_time_progress: ProgressBar = %TimeProgress

## Dictionary containing all tracker configurations
var _track_data: Dictionary = {
	"2D": {"Color": Color.DEEP_SKY_BLUE, "Name": "2D", "Icon": "2D", "Time": 0},
	"3D": {"Color": Color.CORAL, "Name": "3D", "Icon": "3D", "Time": 0},
	"SCRIPT": {"Color": Color.YELLOW, "Name": "Script", "Icon": "Script", "Time": 0},
	"ASSETLIB": {"Color": Color.MEDIUM_SEA_GREEN, "Name": "AssetLib", "Icon": "AssetLib", "Time": 0},
	"GAME": {"Color": Color.MEDIUM_PURPLE, "Name": "Game", "Icon": "Game", "Time": 0}
}

## Current tracker type (2D/3D/SCRIPT/etc)
var tracker_type: String = "2D":
	set(value):
		tracker_type = value.to_upper()
		tracker_name = _track_data[tracker_type]["Name"]
		tracker_icon_color = _track_data[tracker_type]["Color"]
		tracker_icon_texture = _track_data[tracker_type]["Icon"]
		tracker_player_texture = "Pause"
		tracker_time_value = 0
		tracker_time = ''
	get:
		return tracker_type

## Display name for current tracker
var tracker_name: String = '2D':
	set(value):
		tracker_name = value
		_tracker_label.text = value

## Formatted time string display
var tracker_time: String = '':
	set(value):
		_tracker_time_label.text = '00:00:00' if value == '' else value

## Raw time value in seconds
var tracker_time_value: float = 0:
	set(value):
		tracker_time_value = value
		_track_data[tracker_type]["Time"] = value

## Current section icon
var tracker_icon_texture: String = "2D":
	set(value):
		_tracker_icon.texture = get_theme_icon(value, "EditorIcons")
		_tracker_icon.modulate = tracker_icon_color

## Play/pause icon
var tracker_player_texture: String = "Pause":
	set(value):
		_player_icon.texture = get_theme_icon(value, "EditorIcons")
		_player_icon.modulate = tracker_icon_color

## Current color scheme
var tracker_icon_color: Color = Color.WHITE:
	set(value):
		_tracker_icon.modulate = value
	get:
		return _tracker_icon.modulate

func _ready() -> void:
	_tracker_button.pressed.connect(_on_clear_button_pressed)
	_update_theme()
	tracker_time = ""

## Updates editor theme elements
func _update_theme() -> void:
	if Engine.is_editor_hint():
		_tracker_button.icon = get_theme_icon("Remove", "EditorIcons")

## Handles clear button press event
func _on_clear_button_pressed() -> void:
	on_clear_button_pressed.emit(tracker_name)
	
