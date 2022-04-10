@tool
extends Resource

signal done_changed()
signal details_changed()
signal assignee_changed()
signal attachments_changed()

@export var done:bool = false : 
	set(value):
		if done != value:
			done = value
			emit_signal("done_changed")
			emit_changed()

@export_multiline var details:String = "" : 
	set(value):
		if details != value:
			details = value
			emit_signal("details_changed")
			emit_changed()

@export var assignee:String = "" : 
	set(value):
		if assignee != value:
			assignee = value
			emit_signal("assignee_changed")
			emit_changed()

@export var attachments:Array[String] = []

var context = load("res://addons/planner/context.tres")

func is_assigned() -> bool:
	return assignee != ""

func add_attachment(path:String, add_undo:bool = true):
	if not attachments.has(path):
		if context and add_undo:
			var current_attachments = attachments.duplicate()
			var new_attachments = attachments.duplicate()
			new_attachments.append(path)
			
			var undo_redo:UndoRedo = context.undo_redo
			undo_redo.create_action("Add Attachment")
			undo_redo.add_do_property(self, "attachments", new_attachments)
			undo_redo.add_do_method(self, "emit_signal", "attachments_changed")
			undo_redo.add_do_method(self, "emit_changed")
			undo_redo.add_undo_property(self, "attachments", current_attachments)
			undo_redo.add_undo_method(self, "emit_signal", "attachments_changed")
			undo_redo.add_undo_method(self, "emit_changed")
			undo_redo.commit_action(true)
		
		else:
			attachments.append(path)
			emit_signal("attachments_changed")
			emit_changed()

func remove_attachment(path:String, add_undo:bool = true):
	if attachments.has(path):
		
		if context and add_undo:
			var current_attachments = attachments.duplicate()
			var new_attachments = attachments.duplicate()
			new_attachments.erase(path)
			
			var undo_redo:UndoRedo = context.undo_redo
			undo_redo.create_action("Remove Attachment")
			undo_redo.add_do_property(self, "attachments", new_attachments)
			undo_redo.add_do_method(self, "emit_signal", "attachments_changed")
			undo_redo.add_do_method(self, "emit_changed")
			undo_redo.add_undo_property(self, "attachments", current_attachments)
			undo_redo.add_undo_method(self, "emit_signal", "attachments_changed")
			undo_redo.add_undo_method(self, "emit_changed")
			undo_redo.commit_action(true)
		else:
			attachments.erase(path)
			emit_signal("attachments_changed")
			emit_changed()
		
func has_attachment(path:String):
	return attachments.has(path)

func clear_attachments(add_undo = true):
	if context and add_undo:
		var current_attachments = attachments.duplicate()
		var new_attachments = []
		
		var undo_redo:UndoRedo = context.undo_redo
		undo_redo.create_action("Clear Attachments")
		undo_redo.add_do_property(self, "attachments", new_attachments)
		undo_redo.add_do_method(self, "emit_signal", "attachments_changed")
		undo_redo.add_do_method(self, "emit_changed")
		undo_redo.add_undo_property(self, "attachments", current_attachments)
		undo_redo.add_undo_method(self, "emit_signal", "attachments_changed")
		undo_redo.add_undo_method(self, "emit_changed")
		undo_redo.commit_action(true)
	else:
		attachments = []
		emit_signal("attachments_changed")
		emit_changed()
