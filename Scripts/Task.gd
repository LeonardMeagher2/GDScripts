extends Resource
class_name Task

# A Task is used to fire off signals and be able to get a return value
# consumers of these tasks can ask the task to wait before completing so they can do some work
# When a task is complete it won't emit the completed signal again

signal completed(value)
signal before_completed()

enum {
	STATUS_PENDING
	STATUS_COMPLETING
	STATUS_COMPLETED
	STATUS_CANCELLED
}

var value 
var data:Dictionary = {}
var status: = STATUS_PENDING
var _locks = 0

func _init(value = null, data = {}):
	self.value = value
	self.data = data

func lock():
	# lock the task to do async work
	if status == STATUS_PENDING:
		_locks += 1
	else:
		push_warning("Locking a task that is no longer PENDING is not allowed!")

func unlock():
	# when you're done doing async work unlock the task so it can complete
	if status == STATUS_PENDING and _locks > 0:
		_locks -= 1
	else:
		push_warning("Attempt to unlock task, when it was not locked!")
	call_deferred("_done")

func _done():
	if not _locks and status == STATUS_PENDING:
		status = STATUS_COMPLETING
		# synchronous events can change the value before completion here
		# they can also cancel the event
		emit_signal("before_completed") 
		
		# any locking after this will have no effect
		if status == STATUS_COMPLETING:
			status = STATUS_COMPLETED
			emit_signal("completed", value)

func cancel():
	if status == STATUS_PENDING or status == STATUS_COMPLETING:
		status = STATUS_CANCELLED
		# deferred in case the task is cancelled before someone was able to yield for completed
		call_deferred("emit_signal","completed", null)

func done():
	# if we've already completed and we're calling this again
	# emit the signal again without doing much else
	if status == STATUS_CANCELLED:
		push_warning("Calling done on a task multiple times")
		call_deferred("emit_signal","completed", null)
	elif status == STATUS_COMPLETED:
		push_warning("Calling done on a task multiple times")
		call_deferred("emit_signal","completed", value)
	else:
		call_deferred("_done")
