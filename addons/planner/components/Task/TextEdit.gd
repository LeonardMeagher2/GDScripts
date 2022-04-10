@tool
extends TextEdit

func _notification(what):
	if what == NOTIFICATION_DRAG_BEGIN:
		
		var view = get_viewport()
		var drag_data = view.gui_get_drag_data()
		if typeof(drag_data) != TYPE_STRING:
			editable = false
			modulate.a = 0.5
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	elif what == NOTIFICATION_DRAG_END:
		editable = true
		modulate.a = 1.0
		mouse_filter = Control.MOUSE_FILTER_STOP
