## 
## Project Time v1.00 - Godot 4.x Time Tracker Addon -
## Coded By Gianluca D'Angelo (gregbug@gmail.com)
##
## v1.00 - 30 marzo 2025
## 

@tool
extends PanelContainer

## References to UI components
@onready var timer: Timer = %ClockTimer
@onready var time_label: Label = %TimeLabel
@onready var clock_left: TextureRect = $HBoxContainer/ClockLeft
@onready var clock_right: TextureRect = $HBoxContainer/ClockRight

## Color configurations for clock visual states
var clock_normal_color: Color
var clock_over_color: Color
## Current time tracking to minimize unnecessary updates
var current_time: Dictionary = {
	"hour": -1,
	"minute": -1
}

## Multilingual day and month translations
const TRANSLATIONS: Dictionary = {
	"it": {
		"days": ["Dom", "Lun", "Mar", "Mer", "Gio", "Ven", "Sab"],
		"months": ["gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic"]
	},
	"en": {
		"days": ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
		"months": ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	},
	"fr": {
		"days": ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"],
		"months": ["jan", "fev", "mar", "avr", "mai", "juin", "juil", "août", "sep", "oct", "nov", "déc"]
	},
	"es": {
		"days": ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"],
		"months": ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
	},
	"ru": {
		"days": ["Вск", "Пнд", "Втр", "Срд", "Чтв", "Птн", "Сбт"],
		"months": ["янв", "фев", "мар", "апр", "май", "июн", "июл", "авг", "сен", "окт", "ноя", "дек"]
	},
	"pl": {
		"days": ["Nie", "Pon", "Wto", "Śro", "Czw", "Pią", "Sob"],
		"months": ["sty", "lut", "mar", "kwi", "maj", "cze", "lip", "sie", "wrz", "paź", "lis", "gru"]
	},
	"sv": {
		"days": ["Sön", "Mån", "Tis", "Ons", "Tor", "Fre", "Lör"],
		"months": ["jan", "feb", "mar", "apr", "maj", "jun", "jul", "aug", "sep", "okt", "nov", "dec"]
	},
	"pt": {
		"days": ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"],
		"months": ["jan", "fev", "mar", "abr", "mai", "jun", "jul", "ago", "set", "out", "nov", "dez"]
	},
	"de": {
		"days": ["Son", "Mon", "Die", "Mit", "Don", "Fre", "Sam"],
		"months": ["Jan", "Feb", "Mär", "Apr", "Mai", "Jun", "Jul", "Aug", "Sep", "Okt", "Nov", "Dez"]
	}
}

var win_pos: Vector2i
var win_size: Vector2i

## Detect and get system language
func _get_system_language() -> String:
	var lang: String = TranslationServer.get_locale()
	
	# Then check if the language exists in translations
	return lang if lang in TRANSLATIONS else "en"

## Initialize the clock panel
func _ready() -> void:
	theme = get_window().theme
	
	# Set color states for normal and hover
	clock_normal_color = get_theme_color("contrast_color_1", "Editor")
	clock_over_color = get_theme_color("accent_color", "Editor")
	# Initial setup and start timer
	_update_time_display()
	_reset_clock_colors()
	visible = true
	timer.start()

	win_size = DisplayServer.window_get_size()
	win_pos = DisplayServer.window_get_position()

## Update time display when timer triggers
func _on_clock_timer_timeout() -> void:
	_update_time_display()
	
## Handle time display update logic
func _update_time_display() -> void:
	var new_time: Dictionary = Time.get_time_dict_from_system()
	var is_time_changed: bool = (
		new_time.hour != current_time.hour or 
		new_time.minute != current_time.minute
	)
	
	if is_time_changed:
		var date: Dictionary = Time.get_date_dict_from_system()
		time_label.text = _format_time_string(date, new_time)
		current_time = new_time

## Format time string with localized day and month
func _format_time_string(date: Dictionary, time: Dictionary) -> String:
	var lang: String = _get_system_language()
	var translation: Dictionary = TRANSLATIONS[lang]
	
	return "%s %02d %s %02d:%02d" % [
		translation["days"][date.weekday],
		date.day,
		translation["months"][date.month - 1],
		time.hour,
		time.minute
	]

## Handle mouse click for screen mode toggle
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_screen_mode()

## Change clock colors on mouse hover
func _on_mouse_entered() -> void:
	_set_clock_color(clock_over_color)

## Reset clock colors when mouse exits
func _on_mouse_exited() -> void:
	_set_clock_color(clock_normal_color)

## Utility method to set clock colors
func _set_clock_color(color: Color) -> void:
	clock_left.modulate = color
	clock_right.modulate = color

## Reset clock colors to default state
func _reset_clock_colors() -> void:
	_set_clock_color(clock_normal_color)

## Toggle between fullscreen and windowed modes
func _toggle_screen_mode() -> void:
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(win_size)
		DisplayServer.window_set_position(win_pos)
	else:
		win_size = DisplayServer.window_get_size()
		win_pos = DisplayServer.window_get_position()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
