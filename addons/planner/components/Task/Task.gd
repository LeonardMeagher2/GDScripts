@tool
extends PanelContainer

const AttachmentButton = preload("res://addons/planner/components/Attachments/AttachmentButton.tscn")

@export var task:Resource = null :
	set(value):
		if value != task:
			_disconnect_from_task()
			task = value
			_connect_to_task()
			_on_task_changed()

var context = load("res://addons/planner/context.tres")
var editing:bool = false

var ui_done
var ui_text_edit
var ui_attachments
var ui_clear_attachments

func _ready():
	ui_done = $MarginContainer/VBoxContainer/HBoxContainer/Done
	ui_text_edit = $MarginContainer/VBoxContainer/HBoxContainer/TextEdit
	ui_attachments = $MarginContainer/VBoxContainer/HBoxContainer2/Attachments
	ui_clear_attachments = $MarginContainer/VBoxContainer/HBoxContainer2/ClearAttachments
	call_deferred("_on_task_changed")

func _exit_tree():
	_disconnect_from_task()

func _disconnect_from_task():
	if task and task.is_connected("changed", _on_task_changed):
		task.disconnect("changed", _on_task_changed)
func _connect_to_task():
	if task and not task.is_connected("changed", _on_task_changed):
		task.connect("changed", _on_task_changed)

func _on_task_changed():
	if is_inside_tree():
		if not editing:
			ui_done.button_pressed = task.done
			ui_text_edit.text = task.details
		
		for child in ui_attachments.get_children():
			child.queue_free()
		
		for path in task.attachments:
			var attachment_button = AttachmentButton.instantiate()
			attachment_button.path = path
			ui_attachments.add_child(attachment_button)
			
		ui_clear_attachments.visible = task.attachments.size() > 0
	
func _can_drop_data(at_position, data):
	if typeof(data) == TYPE_DICTIONARY and data.get("type") == "files":
		for file in data.files:
			if not task.has_attachment(file):
				return true
	return false

func _drop_data(at_position, data):
	for file in data.files:
		task.add_attachment(file)

func _on_done_toggled(button_pressed):
	editing = true
	if context:
		var undo_redo:UndoRedo = context.undo_redo
		undo_redo.create_action("Set Task Done")
		undo_redo.add_do_property(task, "done", button_pressed)
		undo_redo.add_undo_property(task, "done", task.done)
		undo_redo.commit_action(true)
	else:
		task.done = button_pressed
	editing = false

func _on_remove_attachment_pressed():
	task.clear_attachments()

func _on_text_edit_text_changed():
	editing = true
	task.details = ui_text_edit.text
	editing = false
