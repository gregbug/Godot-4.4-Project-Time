# Project Time  

Godot 4 Time Tracker Addon  

**Developed by Gianluca Domenico D'Angelo**  

Project Time is a plugin developed for Godot 4.4 or later. Its purpose is to accurately measure your development and work time while reminding you to take breaks after long work sessions.  

## Installation  
To install, follow the standard steps for all Godot plugins:  
1. Copy the "Project Time" folder into your project’s `addons` directory.  
2. Enable the plugin via **Project → Project Settings → Plugins**.  

Once enabled, a new dockable tab will appear, which you can resize and position anywhere in the editor.  

## Features  

1. **Current Time & Date**: Displays the current time and date (useful in full-screen mode to keep track of time). Clicking it toggles between windowed and full-screen modes.  

2. **Working Time**:  
   - **Project**: Tracks time spent working on the project, divided into sessions for 2D, 3D, Script, Game, and AssetLib. Each category measures its respective work time.  
   - **Trash Icon**: Resets tracked time. Resetting "Project" clears all data.  
   - **Session**: Measures the duration of the current session.  

3. **External Apps & Idle Time**:  
   - **External Apps**: Tracks time spent on external applications outside the Godot editor.  
   - **Idle**: Measures inactive time (triggers after the interval specified in "Idle After").  

4. **Rest Time Reminder**: Notifies you to take a break after a specified number of minutes (only if enabled).  

5. **Controls**:  
   - Pause or resume the entire plugin using dedicated buttons.  
   - Generate detailed reports with project statistics.  

## Localization  
The plugin supports Italian, English, Spanish, German, and French. To contribute translations or correct existing ones, contact me freely. Localization follows the language set in the Godot editor.  

Translation files are located at:  
`project_time/helpers/translation/languages.csv`  

## Support  
This plugin is completely free. If you find it useful, consider supporting my work by buying me a coffee via PayPal:  
**gregbug@gmail.com**  

Thank you for your support!  
