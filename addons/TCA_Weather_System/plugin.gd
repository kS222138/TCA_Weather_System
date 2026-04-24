@tool
extends EditorPlugin

const WEATHER_SCENE_PATH = "res://addons/TCA_Weather_System/weather_controller.tscn"
const PLUGIN_VERSION = "1.4.0"

func _enter_tree() -> void:
	add_tool_menu_item("Add Weather to Scene", _add_weather_to_scene)
	print("TCA Weather System v%s loaded" % PLUGIN_VERSION)

func _exit_tree() -> void:
	remove_tool_menu_item("Add Weather to Scene")
	print("TCA Weather System v%s unloaded" % PLUGIN_VERSION)

func _add_weather_to_scene() -> void:
	var editor = get_editor_interface()
	if not editor:
		push_error("TCA Weather System: Cannot access editor interface")
		return
	
	var scene_root = editor.get_edited_scene_root()
	if not scene_root:
		push_error("TCA Weather System: No scene is currently open. Please open a scene first.")
		return
	
	if not FileAccess.file_exists(WEATHER_SCENE_PATH):
		push_error("TCA Weather System: weather_controller.tscn not found at %s" % WEATHER_SCENE_PATH)
		return
	
	var weather_scene = load(WEATHER_SCENE_PATH)
	if not weather_scene:
		push_error("TCA Weather System: Failed to load weather_controller.tscn")
		return
	
	var weather_instance = weather_scene.instantiate()
	if not weather_instance:
		push_error("TCA Weather System: Failed to instantiate weather controller")
		return
	
	weather_instance.name = "WeatherController"
	
	var undo_redo = get_undo_redo()
	undo_redo.create_action("Add TCA Weather System")
	undo_redo.add_do_method(scene_root, "add_child", weather_instance)
	undo_redo.add_do_method(weather_instance, "set_owner", scene_root)
	undo_redo.add_undo_method(scene_root, "remove_child", weather_instance)
	undo_redo.commit_action()
	
	print("TCA Weather System: WeatherController added to scene")
	editor.get_selection().clear()
	editor.get_selection().add_node(weather_instance)