@tool
extends EditorPlugin


const Planner = preload("res://addons/planner/Planner.tscn")
const Todo = preload("res://addons/planner/Todo.tscn")

var planner_instance
var todo_instance
var context = load("res://addons/planner/context.tres")

func setup():
	context.editor_interface = get_editor_interface()
	context.undo_redo = get_undo_redo()
	
	planner_instance = Planner.instantiate()
	get_editor_interface().get_editor_main_control().add_child(planner_instance, true)
	_make_visible(false)
	
	todo_instance = Todo.instantiate()
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BL, todo_instance)
	queue_save_layout()

func cleanup():
	if planner_instance:
		planner_instance.queue_free()
		planner_instance = null
	
	if todo_instance:
		remove_control_from_docks(todo_instance)
		todo_instance.queue_free()
		todo_instance = null
	queue_save_layout()

func _enter_tree():
	setup()

func _exit_tree():
	cleanup()

func _make_visible(visible):
	if planner_instance:
		planner_instance.visible = visible

func _get_plugin_name():
	return "Planner"

func _has_main_screen():
	return true

func open_planner():
	if planner_instance:
		_make_visible(true)
		get_editor_interface().set_main_screen_editor(_get_plugin_name())
