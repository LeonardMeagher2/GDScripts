extends UAIInput

# If you only have a start time, returns 1.0 when passed that time
# If you only have an end time, returns 1.0 until passed that time
# If you have a start and end time, return 0.0 when outside of that time and 0-1 when inside schedule

export var start_time:Resource
export var end_time:Resource

func get_value(context:UAIContext) -> float:
	start_time = start_time as Time
	end_time = end_time as Time
	if not (start_time or end_time):
		return 0.0
	
	var value = 1.0
	if start_time and context.current_time < start_time.get_time():
		return 0.0
	if end_time and context.current_time > end_time.get_time():
		return 0.0
	
	if start_time and end_time:
		var minimum = start_time.get_time()
		var maximum = end_time.get_time()
		value = (context.current_time - minimum) / (maximum - minimum)
	
	return value
