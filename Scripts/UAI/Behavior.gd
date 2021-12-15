extends Resource
class_name UAIBehavior

export(int, "Normal", "High") var priority:int = 0
export(Array, Resource) var preconditions:Array
export(Array, Resource) var considerations:Array
export var weight:float = 1.0
export var action:Resource

class Score extends Reference:
	var considerations:Dictionary
	var initial_weight:float
	var final_score:float

func evaluate_preconditions(context:UAIBehaviorContext) -> bool:
	var result = true
	# If one precondition is false we exit early
	for input in preconditions:
		if not input is UAIInput:
			printerr("Behavior precondition must be of type UAIInput")
			continue
		if not input.get_value(context):
			result = false
			break
	return result

func score(context:UAIBehaviorContext) -> Score:
	
	var scores = Score.new()
	scores.initial_weight = weight
	if considerations.size() == 0:
		scores.final_score = weight
		return scores
	
	var compensation = 1.0 - (1.0 / considerations.size())
	var result = weight
	
	
	for consideration in considerations:
		var score:UAIConsideration.Score = consideration.score(context)
		var modification = (1.0 - score.final_score) * compensation
		score.final_score = score.final_score + (modification * score.final_score)
		
		result *= score.final_score
		scores.considerations[consideration] = score
		
	scores.final_score = result
	return scores
