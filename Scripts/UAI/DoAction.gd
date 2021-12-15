extends UAIAction
class_name UAIDoAction

# This is an example how you could implement actions in your game
# this pattern allows agents to control what actually happens, but designers and the AI can still choose an action and ask it to be executed
# just implement a do_action method on your agent to consume these action executions

export var do_on_target:bool = false

func execute(context:UAIBehaviorContext) -> ActionExecution:
	
	var execution = ActionExecution.new(self, context)
	
	var agent
	if do_on_target:
		agent = context.target_ref.get_ref()
	else:
		agent = context.agent_ref.get_ref()
		
		
	if agent and agent.has_method("do_action"):
		agent.do_action(execution)
		return execution
	
	execution.complete()
	return execution
	
	
