/*
State - State Machine Library for 4D
A comprehensive implementation of finite state machines

This library provides:
- State machine creation and management
- Hierarchical/nested states
- Guards (conditional transitions)
- Actions (entry, exit, transition actions)
- Context management
- Actor model for running machines
*/

property version : Text

shared singleton Class constructor
	This:C1470.version:="1.0.0"
	
	//=============================================================================
	// STATIC METHODS (Class-level utilities)
	//=============================================================================
	
/*
Creates a new state machine from configuration
	
@param {Object} $config - Machine configuration
- id: Text - Unique identifier for the machine
- initial: Text - Initial state name
- context: Object - Initial context data
- states: Object - State definitions
	
@returns {cs.StateMachine} - New state machine instance
	
@example
var $machine : cs.StateMachine
var $machine: cs.StateMachine :=cs.State.me.createMachine(New object(\
"id"; "trafficLight";\
"initial"; "green";\
"context"; New object("count"; 0);\
"states"; New object(\
"green"; New object("on"; New object("TIMER"; New object("target"; "yellow")));\
"yellow"; New object("on"; New object("TIMER"; New object("target"; "red")));\
"red"; New object("on"; New object("TIMER"; New object("target"; "green")))\
)\
))
*/
Function createMachine($config : Object) : cs:C1710.StateMachine
	var $machine : cs:C1710.StateMachine
	$machine:=cs:C1710.StateMachine.new($config)
	return $machine
	
/*
Creates and starts an actor from a state machine
	
@param {cs.StateMachine} $machine - The state machine to run
@param {Object} $options - Optional configuration
- id: Text - Actor ID
- input: Variant - Input data for the machine
	
@returns {cs.Actor} - Running actor instance
*/
Function createActor($machine : cs:C1710.StateMachine; $options : Object) : cs:C1710.Actor
	var $actor : cs:C1710.Actor
	If ($options=Null:C1517)
		$options:=New object:C1471
	End if 
	$actor:=cs:C1710.Actor.new($machine; $options)
	return $actor
	
/*
Interprets a state machine (alias for createActor for compatibility)
*/
Function interpret($machine : cs:C1710.StateMachine; $options : Object) : cs:C1710.Actor
	return This:C1470.createActor($machine; $options)
	
/*
Utility to match state values
Returns true if the current state matches the provided state value
	
@param {Variant} $currentState - Current state value (Text or Object for nested states)
@param {Variant} $stateToMatch - State value to match against
@returns {Boolean}
*/
Function matchesState($currentState : Variant; $stateToMatch : Variant) : Boolean
	var $result : Boolean
	$result:=False:C215
	
	Case of 
		: (Value type:C1509($stateToMatch)=Is text:K8:3)
			Case of 
				: (Value type:C1509($currentState)=Is text:K8:3)
					$result:=($currentState=$stateToMatch)
				: (Value type:C1509($currentState)=Is object:K8:27)
					// Check if nested state contains the state
					$result:=(OB Get:C1224($currentState; String:C10($stateToMatch); Is undefined:K8:13)#Null:C1517)
			End case 
			
		: (Value type:C1509($stateToMatch)=Is object:K8:27)
			If (Value type:C1509($currentState)=Is object:K8:27)
				var $key : Text
				var $allMatch : Boolean
				$allMatch:=True:C214
				For each ($key; $stateToMatch)
					If (Not:C34(This:C1470.matchesState(OB Get:C1224($currentState; $key); OB Get:C1224($stateToMatch; $key))))
						$allMatch:=False:C215
					End if 
				End for each 
				$result:=$allMatch
			End if 
	End case 
	
	return $result
	
/*
Converts a state path (e.g., "parent.child") to state value object
	
@param {Text} $path - Dot-separated state path
@returns {Variant} - State value (Text or Object)
*/
Function pathToStateValue($path : Text) : Variant
	var $parts : Collection
	var $result : Variant
	var $current : Object
	var $i : Integer
	
	$parts:=Split string:C1554($path; ".")
	
	If ($parts.length=1)
		return $parts[0]
	End if 
	
	$result:=New object:C1471
	$current:=$result
	
	For ($i; 0; $parts.length-2)
		If ($i=$parts.length-2)
			$current[$parts[$i]]:=$parts[$i+1]
		Else 
			$current[$parts[$i]]:=New object:C1471
			$current:=$current[$parts[$i]]
		End if 
	End for 
	
	return $result
	
	
	
	