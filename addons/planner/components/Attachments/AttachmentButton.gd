@tool
extends Button

const Preview = preload("./Preview.tscn")

var context = load("res://addons/planner/context.tres")

@export var path:String = "" : 
	set(value):
		path = value
		_update()
		
func _ready():
	call_deferred("_update")

func _get_drag_data(at_position):
	var preview = Preview.instantiate()
	preview.icon = icon
	preview.path = path
	set_drag_preview(preview)
	return {
		type = "files",
		files = [path],
		from = get_path()
	}

func _preview_done(path, preview, small_preview, user_data):
	if small_preview:
		icon = small_preview

func _update() -> void:
	var file_type = StringName("File")
	if context:
		var filesystem:EditorFileSystem = context.editor_interface.get_resource_filesystem()
		var preview:EditorResourcePreview = context.editor_interface.get_resource_previewer()
		file_type = filesystem.get_file_type(path)
		
		preview.call_deferred("queue_resource_preview", path, self, "_preview_done", null)
		
	icon = get_theme_icon(file_type, StringName("EditorIcons"))
	hint_tooltip = path


func _on_attachment_button_pressed():
	if context:
		var editor_interface:EditorInterface = context.editor_interface
		var filesystem:EditorFileSystem = editor_interface.get_resource_filesystem()
		var file_type = filesystem.get_file_type(path)
		
		if file_type == "PackedScene":
			editor_interface.open_scene_from_path(path)
		elif file_type == "Script":
			editor_interface.edit_script(load(path))
		else:
			editor_interface.edit_resource(load(path))
