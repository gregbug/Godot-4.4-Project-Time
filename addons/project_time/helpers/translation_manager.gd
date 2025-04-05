## 
## Project Time v1.00 - Godot 4.x Time Tracker Addon -
## Coded By Gianluca D'Angelo (gregbug@gmail.com)
##
## v1.00 - 30 marzo 2025
## 

@tool

# Constants
const TRANSLATIONS_DIR: String = "res://addons/project_time/helpers/translations/"
const DEFAULT_LANGUAGE: String = "en"

# Properties
var current_language: String = DEFAULT_LANGUAGE
var translations: Dictionary = {}

func init() -> void:
	# Ensure translations directory exists
	var dir: DirAccess = DirAccess.open("res://addons/project_time/helpers/")
	if dir:
		dir.make_dir_recursive("translations")
	
	load_translations()
	set_language()

# Translation Management
## Loads all CSV translation files from the translations directory
func load_translations() -> void:
	# Clear existing translations
	translations.clear()
	
	# Load CSV files directly
	var dir: DirAccess = DirAccess.open(TRANSLATIONS_DIR)
	if not dir:
		printerr("Failed to open translations directory: ", TRANSLATIONS_DIR)
		return
		
	# Use list_dir_begin without the deprecated arguments
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".csv"):
			var file_path: String = TRANSLATIONS_DIR + file_name
			parse_csv_translation(file_path)
		file_name = dir.get_next()
	dir.list_dir_end()

## Parses a CSV translation file and loads its contents into the translations dictionary
func parse_csv_translation(file_path: String) -> void:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		printerr("Failed to open translation file: ", file_path)
		return
	
	# Read header line to get languages
	var header: PackedStringArray = file.get_csv_line()
	if header.size() < 2:
		printerr("Invalid CSV format in ", file_path, ", header too short")
		return
	
	# The first column is the key, the rest are language codes
	var languages: Array = header.slice(1)
	
	# Pre-initialize dictionaries for all languages to avoid repeated has() checks
	for lang in languages:
		if not translations.has(lang):
			translations[lang] = {}
	
	# Read and process all lines at once
	while not file.eof_reached():
		var line: PackedStringArray = file.get_csv_line()
		# Skip empty or invalid lines
		if line.is_empty() or line.size() < 2:
			continue
			
		var key: String = line[0]
		# Optimize iteration over languages
		for i in range(min(languages.size(), line.size() - 1)):
			# Apply c_unescape to handle special characters like \n, \t
			translations[languages[i]][key] = line[i + 1].c_unescape()
	
	file.close()

## Sets the current language for translations
func set_language() -> void:
	if translations.has(TranslationServer.get_locale()):
		current_language = TranslationServer.get_locale()
	else:
		current_language = DEFAULT_LANGUAGE

## Translates a given text key with optional format arguments
func translate(key: String, args: Array = []) -> String:
	# Use direct dictionary access with fallback for better performance
	if translations.has(current_language):
		var current_translations: Dictionary = translations[current_language]
		if current_translations.has(key):
			var text: String = current_translations[key]
			# Apply string formatting if args provided
			if not args.is_empty():
				return text % args
			return text
	
	return key  # Return the key if translation not found
