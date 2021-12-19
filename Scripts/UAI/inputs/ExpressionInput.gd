extends UAIInput
class_name UAIExpressionInput

export(String, MULTILINE) var expression:String setget set_expression

var _expression_object:Expression = Expression.new()
var _valid_expression:bool = false

func set_expression(value:String):
	expression = value
	_valid_expression = _expression_object.parse(value, ["agent", "target"]) == OK

func get_value(context:UAIBehaviorContext) -> float:
	var value = 0.0
	
	if not _valid_expression:
		return value
	
	var agent = context.agent_ref.get_ref()
	var target = context.target_ref.get_ref()
		
	if agent and target:
		value = _expression_object.execute([agent, target], context.blackboard)
		if _expression_object.has_execute_failed():
			value = 0.0
		else:
			match typeof(value):
				TYPE_REAL:
					pass
				TYPE_INT, TYPE_BOOL:
					value = float(value)
				_:
					value = 1.0 if value else 0.0
	
	return value
