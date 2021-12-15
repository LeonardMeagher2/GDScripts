extends Resource
class_name UAIConsideration

export var response_curve:Curve
export var input:Resource
export var minimum_value:float = 0.0
export var maximum_value:float = 1.0
export var wrap_value:bool = false

class Score extends Reference:
	var raw_value:float = 0.0
	var value:float = 0.0
	var final_score:float = 0.0

func score(context:UAIBehaviorContext) -> Score:
	
	var score = Score.new()
	
	if not input is UAIInput:
		return score
	
	score.raw_value = input.get_value(context)
	
	# Normalize the raw value
	if wrap_value:
		score.value = fmod(max(minimum_value, score.raw_value), maximum_value - minimum_value)
	else:
		var value = clamp(score.raw_value, minimum_value, maximum_value)
		score.value = (value - minimum_value) / (maximum_value - minimum_value)
	
	# Apply the response curve
	if response_curve:
		score.final_score = response_curve.interpolate_baked(score.value)
	else:
		score.final_score = score.value
	
	return score
