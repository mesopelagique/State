/*
StateMachine - Represents a complete state machine definition

A StateMachine defines:
- States and their configurations
- Initial state
- Context (extended state)
- Implementations (actions, guards, actors, delays)

The StateMachine itself is just a definition - it needs an Actor to run.
*/

property id : Text
property version : Variant
property config : Object
property initialContext : Variant
property initial : Text
property implementations : Object
property idMap : Object
property root : cs:C1710.StateNode
property states : Object
property events : Collection

Class constructor($config : Object; $implementations : Object)
	// Machine identification
	This:C1470.id:=Choose:C955(Length:C16(String:C10($config.id))>0; $config.id; "(machine)")
	This:C1470.version:=$config.version
	
	// Store original configuration
	This:C1470.config:=$config
	
	// Context initialization function or value
	This:C1470.initialContext:=$config.context
	
	// Initial state
	This:C1470.initial:=$config.initial
	
	// Implementations registry
	If ($implementations=Null:C1517)
		$implementations:=New object:C1471
	End if 
	
	This:C1470.implementations:=New object:C1471(\
		"actions"; Choose:C955($implementations.actions#Null:C1517; $implementations.actions; New object:C1471); \
		"guards"; Choose:C955($implementations.guards#Null:C1517; $implementations.guards; New object:C1471); \
		"actors"; Choose:C955($implementations.actors#Null:C1517; $implementations.actors; New object:C1471); \
		"delays"; Choose:C955($implementations.delays#Null:C1517; $implementations.delays; New object:C1471)\
		)
	
	// State node map (id -> StateNode)
	This:C1470.idMap:=New object:C1471
	
	// Build state tree
	This:C1470._buildStateTree()
	
/*
Builds the state tree from configuration
Creates StateNode instances for each state
*/
Function _buildStateTree()
	var $states : Object
	var $stateName : Text
	var $stateConfig : Object
	var $stateNode : cs:C1710.StateNode
	
	// Create root state node
	This:C1470.root:=cs:C1710.StateNode.new(This:C1470.config; New object:C1471(\
		"_key"; This:C1470.id; \
		"_machine"; This:C1470\
		))
	
	// Initialize the tree (builds nested states recursively)
	This:C1470.root._initialize()
	
	// Build reference maps
	This:C1470.states:=This:C1470.root.states
	This:C1470.events:=This:C1470.root.events
	
/*
Clones this state machine with provided implementations
	
@param {Object} $implementations - New implementations to merge
- actions: Object - Action implementations
- guards: Object - Guard implementations  
- actors: Object - Actor implementations
- delays: Object - Delay implementations
	
@returns {cs.StateMachine} - New machine with merged implementations
*/
Function provide($implementations : Object) : cs:C1710.StateMachine
	var $newImplementations : Object
	
	$newImplementations:=New object:C1471(\
		"actions"; This:C1470._mergeObjects(This:C1470.implementations.actions; $implementations.actions); \
		"guards"; This:C1470._mergeObjects(This:C1470.implementations.guards; $implementations.guards); \
		"actors"; This:C1470._mergeObjects(This:C1470.implementations.actors; $implementations.actors); \
		"delays"; This:C1470._mergeObjects(This:C1470.implementations.delays; $implementations.delays)\
		)
	
	return cs:C1710.StateMachine.new(This:C1470.config; $newImplementations)
	
/*
Helper to merge two objects
*/
Function _mergeObjects($base : Object; $overlay : Object) : Object
	var $result : Object
	var $key : Text
	
	$result:=New object:C1471
	
	If ($base#Null:C1517)
		For each ($key; $base)
			$result[$key]:=$base[$key]
		End for each 
	End if 
	
	If ($overlay#Null:C1517)
		For each ($key; $overlay)
			$result[$key]:=$overlay[$key]
		End for each 
	End if 
	
	return $result
	
/*
Gets a state node by its ID
	
@param {Text} $stateId - State node ID (can include # prefix)
@returns {cs.StateNode} - The state node or Null
*/
Function getStateNodeById($stateId : Text) : cs:C1710.StateNode
	var $id : Text
	
	// Remove # prefix if present
	If ($stateId[[1]]="#")
		$id:=Substring:C12($stateId; 2)
	Else 
		$id:=$stateId
	End if 
	
	If (OB Get:C1224(This:C1470.idMap; $id)#Null:C1517)
		return This:C1470.idMap[$id]
	End if 
	
	return Null:C1517
	
/*
Gets state nodes for a given state value
	
@param {Variant} $stateValue - State value (Text or Object)
@returns {Collection} - Collection of StateNode instances
*/
Function getStateNodes($stateValue : Variant) : Collection
	var $nodes : Collection
	var $key : Text
	var $childNodes : Collection
	
	$nodes:=[]
	
	Case of 
		: (Value type:C1509($stateValue)=Is text:K8:3)
			// Simple state
			If (This:C1470.states[$stateValue]#Null:C1517)
				$nodes.push(This:C1470.states[$stateValue])
			End if 
			
		: (Value type:C1509($stateValue)=Is object:K8:27)
			// Nested state value
			For each ($key; $stateValue)
				If (This:C1470.states[$key]#Null:C1517)
					$nodes.push(This:C1470.states[$key])
					// Recursively get child state nodes
					$childNodes:=This:C1470.states[$key].getStateNodes($stateValue[$key])
					$nodes:=$nodes.concat($childNodes)
				End if 
			End for each 
	End case 
	
	return $nodes
	
/*
Resolves a state value to its canonical form
	
@param {Variant} $stateValue - State value to resolve
@returns {Variant} - Resolved state value
*/
Function resolveStateValue($stateValue : Variant) : Variant
	// For now, just return as-is
	// Can be enhanced to handle state ID references
	return $stateValue
	
/*
Gets the initial snapshot for this machine
	
@param {Variant} $input - Input for the machine
@returns {cs.MachineSnapshot} - Initial snapshot
*/
Function getInitialSnapshot($input : Variant) : cs:C1710.MachineSnapshot
	var $context : Object
	var $snapshot : cs:C1710.MachineSnapshot
	
	// Initialize context
	Case of 
		: (Value type:C1509(This:C1470.initialContext)=Is object:K8:27)
			// Clone the context object
			$context:=OB Copy:C1225(This:C1470.initialContext; ck shared:K85:29)
		: (This:C1470.initialContext=Null:C1517)
			$context:=New object:C1471
		Else 
			$context:=New object:C1471
	End case 
	
	// Create initial snapshot
	$snapshot:=cs:C1710.MachineSnapshot.new(New object:C1471(\
		"value"; This:C1470.initial; \
		"context"; $context; \
		"status"; "active"; \
		"machine"; This:C1470\
		))
	
	// Get initial state nodes and execute entry actions
	$snapshot._nodes:=This:C1470.getStateNodes(This:C1470.initial)
	
	return $snapshot
	
/*
Performs a transition from the current snapshot given an event
	
@param {cs.MachineSnapshot} $snapshot - Current snapshot
@param {Object} $event - Event object with at least { type: Text }
@returns {cs.MachineSnapshot} - New snapshot after transition
*/
Function transition($snapshot : cs:C1710.MachineSnapshot; $event : Object) : cs:C1710.MachineSnapshot
	var $nextSnapshot : cs:C1710.MachineSnapshot
	var $stateNodes : Collection
	var $stateNode : cs:C1710.StateNode
	var $transition : Object
	var $i : Integer
	
	// Get state nodes for current state value
	$stateNodes:=This:C1470.getStateNodes($snapshot.value)
	
	// Find applicable transition (search from deepest to root)
	For ($i; $stateNodes.length-1; 0; -1)
		$stateNode:=$stateNodes[$i]
		$transition:=$stateNode.getTransition($event; $snapshot)
		If ($transition#Null:C1517)
			// Found a valid transition
			$nextSnapshot:=This:C1470._executeTransition($snapshot; $transition; $event)
			return $nextSnapshot
		End if 
	End for 
	
	// No transition found - return same snapshot
	return $snapshot
	
/*
Executes a transition and returns new snapshot
	
@param {cs.MachineSnapshot} $snapshot - Current snapshot
@param {Object} $transition - Transition definition
@param {Object} $event - Triggering event
@returns {cs.MachineSnapshot} - New snapshot
*/
Function _executeTransition($snapshot : cs:C1710.MachineSnapshot; $transition : Object; $event : Object) : cs:C1710.MachineSnapshot
	var $newSnapshot : cs:C1710.MachineSnapshot
	var $newContext : Object
	var $newValue : Variant
	var $exitActions : Collection
	var $entryActions : Collection
	var $transitionActions : Collection
	var $oldNodes : Collection
	var $newNodes : Collection
	var $i : Integer
	var $action : Variant
	
	// Clone context
	$newContext:=OB Copy:C1225($snapshot.context; ck shared:K85:29)
	
	// Determine new state value
	If ($transition.target#Null:C1517)
		$newValue:=$transition.target
	Else 
		$newValue:=$snapshot.value
	End if 
	
	// Get old and new state nodes
	$oldNodes:=This:C1470.getStateNodes($snapshot.value)
	$newNodes:=This:C1470.getStateNodes($newValue)
	
	// Collect exit actions (from deepest to shallowest)
	$exitActions:=[]
	For ($i; $oldNodes.length-1; 0; -1)
		If ($newNodes.indexOf($oldNodes[$i])<0)
			$exitActions:=$exitActions.concat($oldNodes[$i].exit)
		End if 
	End for 
	
	// Collect transition actions
	$transitionActions:=[]
	If (Value type:C1509($transition.actions)=Is collection:K8:32)
		$transitionActions:=$transition.actions
	Else 
		If ($transition.actions#Null:C1517)
			$transitionActions.push($transition.actions)
		End if 
	End if 
	
	// Collect entry actions (from shallowest to deepest)
	$entryActions:=[]
	For ($i; 0; $newNodes.length-1)
		If ($oldNodes.indexOf($newNodes[$i])<0)
			$entryActions:=$entryActions.concat($newNodes[$i].entry)
		End if 
	End for 
	
	// Execute all actions in order: exit, transition, entry
	var $allActions : Collection
	$allActions:=$exitActions.concat($transitionActions).concat($entryActions)
	
	For each ($action; $allActions)
		$newContext:=This:C1470._executeAction($action; $newContext; $event)
	End for each 
	
	// Create new snapshot
	$newSnapshot:=cs:C1710.MachineSnapshot.new(New object:C1471(\
		"value"; $newValue; \
		"context"; $newContext; \
		"status"; "active"; \
		"machine"; This:C1470\
		))
	
	$newSnapshot._nodes:=$newNodes
	
	// Check if final state
	If ($newNodes.length>0)
		If ($newNodes[$newNodes.length-1].type="final")
			$newSnapshot.status:="done"
		End if 
	End if 
	
	return $newSnapshot
	
/*
Executes an action and returns updated context
	
@param {Variant} $action - Action to execute
@param {Object} $context - Current context
@param {Object} $event - Current event
@returns {Object} - Updated context
*/
Function _executeAction($action : Variant; $context : Object; $event : Object) : Object
	var $actionName : Text
	var $actionFn : 4D:C1709.Function
	var $actionDef : Object
	var $newContext : Object
	var $params : Object
	
	$newContext:=$context
	
	Case of 
		: (Value type:C1509($action)=Is text:K8:3)
			// Named action - look up in implementations
			$actionName:=$action
			$actionFn:=This:C1470.implementations.actions[$actionName]
			If ($actionFn#Null:C1517)
				$newContext:=$actionFn.call(This:C1470; New object:C1471("context"; $context; "event"; $event))
				If ($newContext=Null:C1517)
					$newContext:=$context
				End if 
			End if 
			
		: (Value type:C1509($action)=Is object:K8:27)
			// Action object with type and possibly params
			$actionDef:=$action
			$actionName:=String:C10($actionDef.type)
			$params:=$actionDef.params
			
			Case of 
				: ($actionName="stateassign")
					// Built-in assign action
					$newContext:=This:C1470._executeAssign($actionDef; $context; $event)
					
				: ($actionName="statelog")
					// Built-in log action
					This:C1470._executeLog($actionDef; $context; $event)
					
				: ($actionName="stateraise")
					// Raise action - will be handled by actor
					// Store in context for actor to process
					If ($newContext._raisedEvents=Null:C1517)
						$newContext._raisedEvents:=[]
					End if 
					$newContext._raisedEvents.push($actionDef.event)
					
				Else 
					// Custom action - look up in implementations
					$actionFn:=This:C1470.implementations.actions[$actionName]
					If ($actionFn#Null:C1517)
						$newContext:=$actionFn.call(This:C1470; New object:C1471("context"; $context; "event"; $event; "params"; $params))
						If ($newContext=Null:C1517)
							$newContext:=$context
						End if 
					End if 
			End case 
	End case 
	
	return $newContext
	
/*
Executes the built-in assign action
*/
Function _executeAssign($actionDef : Object; $context : Object; $event : Object) : Object
	var $key : Text
	var $value : Variant
	var $fn : 4D:C1709.Function
	
	var $newContext:=OB Copy:C1225($context; ck shared:K85:29)
	var $assignment : Object:=$actionDef.assignment
	
	If ($assignment#Null:C1517)
		Use ($newContext)
			Case of 
				: (Value type:C1509($assignment)=Is object:K8:27)
					// Object with property assignments
					For each ($key; $assignment)
						$value:=$assignment[$key]
						If ((Value type:C1509($value)=Is object:K8:27) && (OB Instance of:C1731($value; 4D:C1709.Function)))
							// Function - call it with context and event
							$fn:=$value
							$value:=$fn.call(Null:C1517; New object:C1471("context"; $context; "event"; $event))
						End if 
						
						Case of 
							: (Value type:C1509($value)=Is object:K8:27)
								$newContext[$key]:=OB Copy:C1225($value; ck shared:K85:29; $newContext)
							: (Value type:C1509($value)=Is collection:K8:32)
								$newContext[$key]:=$value.copy(ck shared:K85:29; $newContext)
							Else 
								$newContext[$key]:=$value
						End case 
						
					End for each 
			End case 
		End use 
	End if 
	
	return $newContext
	
/*
Executes the built-in log action
*/
Function _executeLog($actionDef : Object; $context : Object; $event : Object)
	var $message : Text
	var $expr : Variant
	
	$expr:=$actionDef.expr
	
	Case of 
		: (Value type:C1509($expr)=Is text:K8:3)
			$message:=$expr
		: (Value type:C1509($expr)=Is object:K8:27)
			If (OB Instance of:C1731($expr; 4D:C1709.Function))
				$message:=String:C10($expr.call(Null:C1517; New object:C1471("context"; $context; "event"; $event)))
			Else 
				$message:=JSON Stringify:C1217($expr)
			End if 
		Else 
			$message:="Event: "+String:C10($event.type)
	End case 
	
	TRACE:C157  // In 4D, we can use TRACE or a custom logging mechanism
	
/*
Converts machine to JSON representation
*/
Function toJSON() : Object
	return This:C1470.root.definition
	
	