tool
extends Resource
class_name UAIBehavior

export(int, "Normal", "High") var priority:int = 0
export(Array, Resource) var preconditions:Array
export(Array, Resource) var considerations:Array setget set_considerations
export var weight:float = 1.0
export var action:Resource

var consideration_weights = {}

class Score extends Reference:
	var considerations:Dictionary
	var initial_weight:float
	var final_score:float

func _get(property):
	if property.begins_with("consideration_weights/"):
		var name = property.split("/",false,1)
		if name.size() == 2:
			return consideration_weights[name[1]]
	return null

func _set(property,value):
	print(property)
	if property.begins_with("consideration_weights/"):
		var name = property.split("/",false,1)
		print(name)
		if name.size() == 2:
			consideration_weights[name[1]] = value
			return true
	return false
	
func set_considerations(value:Array):
	considerations = value
	var old_weights = consideration_weights
	consideration_weights = {}
	for consideration in considerations:
		if old_weights.has(consideration.name):
			consideration_weights[consideration.name] = old_weights.get(consideration.name)
		else:
			consideration_weights[consideration.name] = 1
	property_list_changed_notify()

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
	for consideration_weight in consideration_weights.values():
		result += consideration_weight
	
	for consideration in considerations:
		var score:UAIConsideration.Score = consideration.score(context)
		var modification = (1.0 - score.final_score) * compensation
		score.final_score = score.final_score + (modification * score.final_score)
		
		result *= score.final_score
		scores.considerations[consideration] = score
		
	scores.final_score = result
	return scores

func _get_property_list():
	var res = [{
		name = "Consideration Weights",
		type = TYPE_NIL,
		hint_string = "consideration_weight_",
		usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	}]
	for consideration in considerations:
		res.append({
			name = "consideration_weights/"+consideration.name,
			type = TYPE_REAL,
			hint_string = "consideration_weight_" + consideration.name,
			usage = PROPERTY_USAGE_DEFAULT
		})
	return res
