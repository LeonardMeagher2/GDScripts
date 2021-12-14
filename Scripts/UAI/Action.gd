extends Resource
class_name UAIAction

signal completed()

func execute(context:UAIContext, delta:float) -> void:
	call_deferred("emit_signal", "completed")
