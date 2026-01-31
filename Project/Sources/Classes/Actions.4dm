/*
Actions - Helper class for creating state machine actions

Actions are side effects that execute during state transitions.
They can be:
- Entry actions: Execute when entering a state
- Exit actions: Execute when leaving a state
- Transition actions: Execute during a transition

Built-in action creators:
- assign(assignment): Updates context
- raise(event): Raises an event to self
- log(expr): Logs a message
- sendTo(actorRef, event): Sends event to another actor
- stop(actorRef): Stops a spawned actor

Usage:
var $action := cs.Actions.me.assign(New object("count"; Formula($1.context.count + 1)))
var $action := cs.Actions.me.raise("NEXT")
var $action := cs.Actions.me.log("State changed")
*/

shared singleton Class constructor
	// Singleton pattern for accessing action creators
	
/*
Creates an assign action that updates context
	
@param {Object} $assignment - Object with assignments
  Keys are context property names
  Values can be:
    - Static values
    - Formula objects that receive {context, event} and return new value
	
@returns {Object} - Action definition
	
@example
// Static assignment
cs.Actions.assign(New object("count"; 0))
	
// Dynamic assignment with Formula
cs.Actions.assign(New object(\
"count"; Formula($1.context.count + 1);\
"lastEvent"; Formula($1.event.type)\
))
*/
Function assign($assignment : Object) : Object
	var $action : Object
	
	$action:=New object:C1471
	$action.type:="stateassign"
	$action.assignment:=$assignment
	
	return $action
	
/*
Creates a raise action that sends an event to itself
	
@param {Variant} $event - Event to raise (Text or Object)
@returns {Object} - Action definition
	
@example
cs.Actions.raise("NEXT")
cs.Actions.raise(New object("type"; "UPDATE"; "data"; 42))
*/
Function raise($event : Variant) : Object
	var $action : Object
	var $eventObj : Variant
	
	// Normalize event
	Case of 
		: (Value type:C1509($event)=Is text:K8:3)
			$eventObj:=New object:C1471("type"; $event)
		Else 
			$eventObj:=$event
	End case 
	
	$action:=New object:C1471
	$action.type:="stateraise"
	$action.event:=$eventObj
	
	return $action
	
/*
Creates a log action
	
@param {Variant} $expr - Expression to log
  - Text: Static message
  - Formula: Function that receives {context, event} and returns message
	
@returns {Object} - Action definition
	
@example
cs.Actions.log("Entered state")
cs.Actions.log(Formula("Count is: "+String($1.context.count)))
*/
Function log($expr : Variant) : Object
	var $action : Object
	
	$action:=New object:C1471
	$action.type:="statelog"
	$action.expr:=$expr
	
	return $action
	
/*
Creates a sendTo action that sends an event to another actor
	
@param {Variant} $actorRef - Actor reference or ID
@param {Variant} $event - Event to send
	
@returns {Object} - Action definition
*/
Function sendTo($actorRef : Variant; $event : Variant) : Object
	var $action : Object
	var $eventObj : Variant
	
	// Normalize event
	Case of 
		: (Value type:C1509($event)=Is text:K8:3)
			$eventObj:=New object:C1471("type"; $event)
		Else 
			$eventObj:=$event
	End case 
	
	$action:=New object:C1471
	$action.type:="statesendTo"
	$action.to:=$actorRef
	$action.event:=$eventObj
	
	return $action
	
/*
Creates a sendParent action that sends an event to parent actor
	
@param {Variant} $event - Event to send
@returns {Object} - Action definition
*/
Function sendParent($event : Variant) : Object
	var $action : Object
	var $eventObj : Variant
	
	// Normalize event
	Case of 
		: (Value type:C1509($event)=Is text:K8:3)
			$eventObj:=New object:C1471("type"; $event)
		Else 
			$eventObj:=$event
	End case 
	
	$action:=New object:C1471
	$action.type:="statesendParent"
	$action.event:=$eventObj
	
	return $action
	
/*
Creates a stop action that stops a spawned actor
	
@param {Variant} $actorRef - Actor reference or ID
@returns {Object} - Action definition
*/
Function stop($actorRef : Variant) : Object
	var $action : Object
	
	$action:=New object:C1471
	$action.type:="statestop"
	$action.actor:=$actorRef
	
	return $action
	
/*
Creates a named action reference with optional params
	
@param {Text} $actionName - Name of the action
@param {Object} $params - Optional parameters
@returns {Object} - Action definition
*/
Function ref($actionName : Text; $params : Object) : Object
	var $action : Object
	
	$action:=New object:C1471
	$action.type:=$actionName
	If ($params#Null:C1517)
		$action.params:=$params
	End if 
	
	return $action
	
/*
Creates an emit action that emits an event for listeners
	
@param {Variant} $event - Event to emit
@returns {Object} - Action definition
*/
Function emit($event : Variant) : Object
	var $action : Object
	var $eventObj : Variant
	
	Case of 
		: (Value type:C1509($event)=Is text:K8:3)
			$eventObj:=New object:C1471("type"; $event)
		Else 
			$eventObj:=$event
	End case 
	
	$action:=New object:C1471
	$action.type:="stateemit"
	$action.event:=$eventObj
	
	return $action
	
/*
Creates a cancel action that cancels a delayed event/action
	
@param {Text} $id - ID of the delayed action to cancel
@returns {Object} - Action definition
*/
Function cancel($id : Text) : Object
	var $action : Object
	
	$action:=New object:C1471
	$action.type:="statecancel"
	$action.id:=$id
	
	return $action
	
/*
Creates a pure action that computes actions dynamically
	
@param {4D.Function} $fn - Function that returns actions array
  Receives {context, event} and returns Collection of actions
	
@returns {Object} - Action definition
*/
Function pure($fn : 4D:C1709.Function) : Object
	var $action : Object
	
	$action:=New object:C1471
	$action.type:="statepure"
	$action.fn:=$fn
	
	return $action
	