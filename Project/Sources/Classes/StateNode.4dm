/*
StateNode - Represents a single state node in a state machine

A StateNode can be:
- atomic: No child states
- compound: Has child states (XOR - only one active at a time)
- parallel: Has child states (AND - all active simultaneously)
- final: Terminal state
- history: History state (shallow or deep)

Each state node has:
- Entry actions (executed when entering the state)
- Exit actions (executed when leaving the state)
- Transitions (event handlers)
- Child states (for compound/parallel states)
*/

property config : Object
property parent : cs:C1710.StateNode
property machine : cs:C1710.StateMachine
property key : Text
property path : Collection
property id : Text
property type : Text
property description : Text
property order : Integer
property states : Object
property initial : Text
property history : Variant
property entry : Collection
property exit : Collection
property meta : Variant
property output : Variant
property tags : Collection
property transitions : Object
property always : Collection
/*
Gets all events accepted by this state and its descendants
*/
property events : Collection
/*
Gets the state node definition for serialization
*/
property definition : Object

Class constructor($config : Object; $options : Object)
	// Store raw configuration
	This:C1470.config:=$config
	
	// Set parent and machine references
	This:C1470.parent:=$options._parent
	This:C1470.machine:=$options._machine
	This:C1470.key:=$options._key
	
	// Build path
	If (This:C1470.parent#Null:C1517)
		This:C1470.path:=This:C1470.parent.path.concat([This:C1470.key])
	Else 
		This:C1470.path:=[]
	End if 
	
	// Build ID
	If (Length:C16(String:C10($config.id))>0)
		This:C1470.id:=$config.id
	Else 
		var $pathParts : Collection
		$pathParts:=[This:C1470.machine.id].concat(This:C1470.path)
		This:C1470.id:=$pathParts.join(".")
	End if 
	
	// Determine state type
	This:C1470.type:=This:C1470._determineType()
	
	// Description
	This:C1470.description:=$config.description
	
	// Register in machine's ID map
	This:C1470.order:=OB Keys:C1719(This:C1470.machine.idMap).length
	This:C1470.machine.idMap[This:C1470.id]:=This:C1470
	
	// Initialize child states
	This:C1470.states:=New object:C1471
	This:C1470._buildChildStates()
	
	// Validate compound states have initial
	If (This:C1470.type="compound")
		If (Length:C16(String:C10($config.initial))=0)
			var $childKeys : Collection
			$childKeys:=OB Keys:C1719(This:C1470.states)
			If ($childKeys.length>0)
				This:C1470.config.initial:=$childKeys[0]
			End if 
		End if 
		This:C1470.initial:=This:C1470.config.initial
	End if 
	
	// History configuration
	Case of 
		: ($config.history=True:C214)
			This:C1470.history:="shallow"
		: (Value type:C1509($config.history)=Is text:K8:3)
			This:C1470.history:=$config.history
		Else 
			This:C1470.history:=False:C215
	End case 
	
	// Entry and exit actions
	This:C1470.entry:=This:C1470._toArray($config.entry)
	This:C1470.exit:=This:C1470._toArray($config.exit)
	
	// Meta data
	This:C1470.meta:=$config.meta
	
	// Output (for final states)
	If ((This:C1470.type="final") | (This:C1470.parent=Null:C1517))
		This:C1470.output:=$config.output
	End if 
	
	// Tags
	This:C1470.tags:=This:C1470._toArray($config.tags)
	
	// Transitions map will be built during initialization
	This:C1470.transitions:=New object:C1471
	
	// Always transitions (checked on every microstep)
	This:C1470.always:=Null:C1517
	
/*
Determines the state type from configuration
*/
Function _determineType() : Text
	var $type : Text
	
	If (Length:C16(String:C10(This:C1470.config.type))>0)
		return This:C1470.config.type
	End if 
	
	Case of 
		: ((This:C1470.config.states#Null:C1517) && (OB Keys:C1719(This:C1470.config.states).length>0))
			$type:="compound"
		: (This:C1470.config.history#Null:C1517)
			$type:="history"
		Else 
			$type:="atomic"
	End case 
	
	return $type
	
/*
Builds child state nodes recursively
*/
Function _buildChildStates()
	var $states : Object
	var $stateName : Text
	var $stateConfig : Object
	var $stateNode : cs:C1710.StateNode
	
	$states:=This:C1470.config.states
	
	If ($states=Null:C1517)
		return 
	End if 
	
	For each ($stateName; $states)
		$stateConfig:=$states[$stateName]
		
		// Ensure stateConfig is an object
		If ($stateConfig=Null:C1517)
			$stateConfig:=New object:C1471
		End if 
		
		$stateNode:=cs:C1710.StateNode.new($stateConfig; New object:C1471(\
			"_parent"; This:C1470; \
			"_key"; $stateName; \
			"_machine"; This:C1470.machine\
			))
		
		This:C1470.states[$stateName]:=$stateNode
	End for each 
	
/*
Initializes transitions after all states are built
*/
Function _initialize()
	var $stateName : Text
	
	// Build transitions
	This:C1470._buildTransitions()
	
	// Build always transitions
	If (This:C1470.config.always#Null:C1517)
		This:C1470.always:=This:C1470._formatTransitions(This:C1470.config.always; "")
	End if 
	
	// Initialize child states recursively
	For each ($stateName; This:C1470.states)
		This:C1470.states[$stateName]._initialize()
	End for each 
	
/*
Builds the transitions map from the 'on' configuration
*/
Function _buildTransitions()
	var $on : Object
	var $eventType : Text
	var $transitionConfig : Variant
	var $transitions : Collection
	
	$on:=This:C1470.config.on
	
	If ($on=Null:C1517)
		return 
	End if 
	
	For each ($eventType; $on)
		$transitionConfig:=$on[$eventType]
		$transitions:=This:C1470._formatTransitions($transitionConfig; $eventType)
		This:C1470.transitions[$eventType]:=$transitions
	End for each 
	
/*
Formats transition configuration into standardized transition objects
	
@param {Variant} $config - Transition config (Text, Object, or Collection)
@param {Text} $eventType - The event type for this transition
@returns {Collection} - Collection of transition definitions
*/
Function _formatTransitions($config : Variant; $eventType : Text) : Collection
	var $transitions : Collection
	var $transition : Object
	var $item : Variant
	var $configArray : Collection
	
	$transitions:=[]
	
	Case of 
		: ($config=Null:C1517)
			// No transition
			
		: (Value type:C1509($config)=Is text:K8:3)
			// Simple target string
			$transitions.push(New object:C1471(\
				"target"; $config; \
				"eventType"; $eventType; \
				"source"; This:C1470; \
				"actions"; New collection:C1472; \
				"guard"; Null:C1517; \
				"reenter"; False:C215\
				))
			
		: (Value type:C1509($config)=Is object:K8:27)
			// Single transition object
			$transition:=This:C1470._formatSingleTransition($config; $eventType)
			$transitions.push($transition)
			
		: (Value type:C1509($config)=Is collection:K8:32)
			// Array of transitions (for guards)
			$configArray:=$config
			For each ($item; $configArray)
				Case of 
					: (Value type:C1509($item)=Is text:K8:3)
						$transitions.push(New object:C1471(\
							"target"; $item; \
							"eventType"; $eventType; \
							"source"; This:C1470; \
							"actions"; New collection:C1472; \
							"guard"; Null:C1517; \
							"reenter"; False:C215\
							))
					: (Value type:C1509($item)=Is object:K8:27)
						$transition:=This:C1470._formatSingleTransition($item; $eventType)
						$transitions.push($transition)
				End case 
			End for each 
	End case 
	
	return $transitions
	
/*
Formats a single transition configuration object
	
@param {Object} $config - Transition configuration
@param {Text} $eventType - Event type
@returns {Object} - Formatted transition definition
*/
Function _formatSingleTransition($config : Object; $eventType : Text) : Object
	var $transition : Object
	
	$transition:=New object:C1471
	$transition.eventType:=$eventType
	$transition.source:=This:C1470
	
	// Target
	If ($config.target#Null:C1517)
		$transition.target:=$config.target
	Else 
		$transition.target:=Null:C1517  // Internal transition
	End if 
	
	// Actions
	$transition.actions:=This:C1470._toArray($config.actions)
	
	// Guard
	$transition.guard:=$config.guard
	If ($transition.guard=Null:C1517)
		$transition.guard:=$config.cond  // Legacy 'cond' support
	End if 
	
	// Reenter flag
	$transition.reenter:=Choose:C955($config.reenter=True:C214; True:C214; False:C215)
	
	// Meta
	$transition.meta:=$config.meta
	
	// Description
	$transition.description:=$config.description
	
	return $transition
	
/*
Gets a valid transition for an event
	
@param {Object} $event - Event object
@param {cs.MachineSnapshot} $snapshot - Current snapshot
@returns {Object} - Transition definition or Null
*/
Function getTransition($event : Object; $snapshot : cs:C1710.MachineSnapshot) : Object
	var $eventType : Text
	var $transitions : Collection
	var $transition : Object
	var $guardPassed : Boolean
	
	$eventType:=$event.type
	
	// Get candidate transitions for this event type
	If (This:C1470.transitions[$eventType]=Null:C1517)
		// Also check for wildcard transitions
		If (This:C1470.transitions["*"]=Null:C1517)
			return Null:C1517
		End if 
		$transitions:=This:C1470.transitions["*"]
	Else 
		$transitions:=This:C1470.transitions[$eventType]
	End if 
	
	// Find first transition where guard passes
	For each ($transition; $transitions)
		$guardPassed:=This:C1470._evaluateGuard($transition.guard; $snapshot; $event)
		If ($guardPassed)
			return $transition
		End if 
	End for each 
	
	return Null:C1517
	
/*
Evaluates a guard condition
	
@param {Variant} $guard - Guard definition
@param {cs.MachineSnapshot} $snapshot - Current snapshot
@param {Object} $event - Current event
@returns {Boolean} - True if guard passes
*/
Function _evaluateGuard($guard : Variant; $snapshot : cs:C1710.MachineSnapshot; $event : Object) : Boolean
	var $guardFn : 4D:C1709.Function
	var $guardName : Text
	var $result : Boolean
	var $guardObj : Object
	
	If ($guard=Null:C1517)
		return True:C214  // No guard = always passes
	End if 
	
	Case of 
		: (Value type:C1509($guard)=Is text:K8:3)
			// Named guard - look up in implementations
			$guardName:=$guard
			$guardFn:=This:C1470.machine.implementations.guards[$guardName]
			If ($guardFn#Null:C1517)
				$result:=$guardFn.call(This:C1470.machine; New object:C1471(\
					"context"; $snapshot.context; \
					"event"; $event\
					))
				return $result
			Else 
				// Guard not found - fail safe
				return False:C215
			End if 
			
		: (Value type:C1509($guard)=Is object:K8:27)
			$guardObj:=$guard
			
			Case of 
				: ($guardObj.type="stateand")
					// AND guard - all must pass
					return This:C1470._evaluateAndGuard($guardObj.guards; $snapshot; $event)
					
				: ($guardObj.type="stateor")
					// OR guard - at least one must pass
					return This:C1470._evaluateOrGuard($guardObj.guards; $snapshot; $event)
					
				: ($guardObj.type="statenot")
					// NOT guard - invert result
					return Not:C34(This:C1470._evaluateGuard($guardObj.guard; $snapshot; $event))
					
				: ($guardObj.type="statestateIn")
					// StateIn guard - check if in state
					return cs:C1710.State.me.matchesState($snapshot.value; $guardObj.stateValue)
					
				: (Length:C16(String:C10($guardObj.type))>0)
					// Named guard with params
					$guardName:=$guardObj.type
					$guardFn:=This:C1470.machine.implementations.guards[$guardName]
					If ($guardFn#Null:C1517)
						$result:=$guardFn.call(This:C1470.machine; New object:C1471(\
							"context"; $snapshot.context; \
							"event"; $event; \
							"params"; $guardObj.params\
							))
						return $result
					End if 
					
				Else 
					// Inline guard function
					If (OB Instance of:C1731($guard; 4D:C1709.Function))
						$guardFn:=$guard
						$result:=$guardFn.call(Null:C1517; New object:C1471(\
							"context"; $snapshot.context; \
							"event"; $event\
							))
						return $result
					End if 
			End case 
	End case 
	
	return False:C215
	
/*
Evaluates AND guard
*/
Function _evaluateAndGuard($guards : Collection; $snapshot : cs:C1710.MachineSnapshot; $event : Object) : Boolean
	var $guard : Variant
	
	If ($guards=Null:C1517)
		return True:C214
	End if 
	
	For each ($guard; $guards)
		If (Not:C34(This:C1470._evaluateGuard($guard; $snapshot; $event)))
			return False:C215
		End if 
	End for each 
	
	return True:C214
	
/*
Evaluates OR guard
*/
Function _evaluateOrGuard($guards : Collection; $snapshot : cs:C1710.MachineSnapshot; $event : Object) : Boolean
	var $guard : Variant
	
	If ($guards=Null:C1517)
		return False:C215
	End if 
	
	For each ($guard; $guards)
		If (This:C1470._evaluateGuard($guard; $snapshot; $event))
			return True:C214
		End if 
	End for each 
	
	return False:C215
	
/*
Gets state nodes for a given state value (for nested states)
*/
Function getStateNodes($stateValue : Variant) : Collection
	var $nodes : Collection
	var $key : Text
	var $childNodes : Collection
	var $childValue : Variant
	
	$nodes:=[]
	
	Case of 
		: (Value type:C1509($stateValue)=Is text:K8:3)
			If (This:C1470.states[$stateValue]#Null:C1517)
				$nodes.push(This:C1470.states[$stateValue])
				// If the child has an initial state, include that too
				If (This:C1470.states[$stateValue].type="compound")
					$childNodes:=This:C1470.states[$stateValue].getStateNodes(This:C1470.states[$stateValue].initial)
					$nodes:=$nodes.concat($childNodes)
				End if 
			End if 
			
		: (Value type:C1509($stateValue)=Is object:K8:27)
			For each ($key; $stateValue)
				If (This:C1470.states[$key]#Null:C1517)
					$nodes.push(This:C1470.states[$key])
					$childValue:=$stateValue[$key]
					$childNodes:=This:C1470.states[$key].getStateNodes($childValue)
					$nodes:=$nodes.concat($childNodes)
				End if 
			End for each 
	End case 
	
	return $nodes
	
	
Function get events() : Collection
	var $allEvents : Collection
	var $stateName : Text
	var $childEvents : Collection
	var $eventType : Text
	
	$allEvents:=[]
	
	// Get own events
	For each ($eventType; This:C1470.transitions)
		$allEvents.push($eventType)
	End for each 
	
	// Get child state events
	For each ($stateName; This:C1470.states)
		$childEvents:=This:C1470.states[$stateName].events
		For each ($eventType; $childEvents)
			If ($allEvents.indexOf($eventType)<0)
				$allEvents.push($eventType)
			End if 
		End for each 
	End for each 
	
	return $allEvents
	
	
	
Function get definition() : Object
	var $def : Object
	var $stateName : Text
	
	$def:=New object:C1471
	$def.id:=This:C1470.id
	$def.key:=This:C1470.key
	$def.type:=This:C1470.type
	$def.initial:=This:C1470.initial
	$def.history:=This:C1470.history
	$def.entry:=This:C1470.entry
	$def.exit:=This:C1470.exit
	$def.meta:=This:C1470.meta
	$def.tags:=This:C1470.tags
	$def.order:=This:C1470.order
	$def.description:=This:C1470.description
	
	// Child states
	$def.states:=New object:C1471
	For each ($stateName; This:C1470.states)
		$def.states[$stateName]:=This:C1470.states[$stateName].definition
	End for each 
	
	// Transitions
	$def.on:=This:C1470.transitions
	
	return $def
	
/*
Helper to convert value to array/collection
*/
Function _toArray($value : Variant) : Collection
	var $result : Collection
	
	Case of 
		: ($value=Null:C1517)
			$result:=[]
		: (Value type:C1509($value)=Is collection:K8:32)
			$result:=$value
		Else 
			$result:=[$value]
	End case 
	
	return $result
	
/*
JSON serialization
*/
Function toJSON() : Object
	return This:C1470.definition
	
	