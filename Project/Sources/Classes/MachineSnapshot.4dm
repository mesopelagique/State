/*
MachineSnapshot - Represents a point-in-time snapshot of machine state

A snapshot contains:
- value: The current state value
- context: The extended state (data)
- status: "active", "done", or "error"
- output: Output value (when done)
- error: Error (when error status)

Snapshots are immutable - transitions create new snapshots.
*/

property value : Variant
property context : Object
property status : Text
property machine : cs:C1710.StateMachine
property output : Variant
property error : Variant
property historyValue : Variant
property children : Object
property _nodes : Collection
property tags : Collection

Class constructor($config : Object)
	// State value (Text for simple states, Object for nested)
	This:C1470.value:=$config.value
	
	// Context (extended state data)
	This:C1470.context:=Choose:C955($config.context#Null:C1517; $config.context; New object:C1471)
	
	// Status: "active", "done", "error"
	This:C1470.status:=Choose:C955(Length:C16(String:C10($config.status))>0; $config.status; "active")
	
	// Machine reference
	This:C1470.machine:=$config.machine
	
	// Output (for final states)
	This:C1470.output:=$config.output
	
	// Error (for error status)
	This:C1470.error:=$config.error
	
	// History value
	This:C1470.historyValue:=$config.historyValue
	
	// Children (spawned actors)
	This:C1470.children:=Choose:C955($config.children#Null:C1517; $config.children; New object:C1471)
	
	// Internal: state nodes in current configuration
	This:C1470._nodes:=$config._nodes
	If (This:C1470._nodes=Null:C1517)
		This:C1470._nodes:=[]
	End if 
	
	// Tags from active state nodes
	This:C1470.tags:=This:C1470._collectTags()
	
/*
Collects tags from all active state nodes
*/
Function _collectTags() : Collection
	var $allTags : Collection
	var $node : cs:C1710.StateNode
	var $tag : Text
	
	$allTags:=[]
	
	For each ($node; This:C1470._nodes)
		If ($node.tags#Null:C1517)
			For each ($tag; $node.tags)
				If ($allTags.indexOf($tag)<0)
					$allTags.push($tag)
				End if 
			End for each 
		End if 
	End for each 
	
	return $allTags
	
/*
Checks if snapshot matches a given state value
	
@param {Variant} $stateValue - State value to match
@returns {Boolean}
*/
Function matches($stateValue : Variant) : Boolean
	return cs:C1710.State.me.matchesState(This:C1470.value; $stateValue)
	
/*
Checks if the snapshot has a specific tag
	
@param {Text} $tag - Tag to check
@returns {Boolean}
*/
Function hasTag($tag : Text) : Boolean
	return (This:C1470.tags.indexOf($tag)>=0)
	
/*
Checks if snapshot is in a final state
*/
Function get done() : Boolean
	return (This:C1470.status="done")
	
/*
Checks if snapshot can handle an event
	
@param {Variant} $event - Event to check
@returns {Boolean}
*/
Function can($event : Variant) : Boolean
	var $eventType : Text
	var $nodes : Collection
	var $node : cs:C1710.StateNode
	
	// Get event type
	Case of 
		: (Value type:C1509($event)=Is text:K8:3)
			$eventType:=$event
		: (Value type:C1509($event)=Is object:K8:27)
			$eventType:=$event.type
		Else 
			return False:C215
	End case 
	
	// Check if any active state node can handle this event
	$nodes:=This:C1470._nodes
	
	For each ($node; $nodes)
		If ($node.transitions[$eventType]#Null:C1517)
			return True:C214
		End if 
		// Also check for wildcard
		If ($node.transitions["*"]#Null:C1517)
			return True:C214
		End if 
	End for each 
	
	return False:C215
	
/*
Gets all events that can currently be handled
*/
Function get nextEvents() : Collection
	var $events : Collection
	var $nodes : Collection
	var $node : cs:C1710.StateNode
	var $eventType : Text
	
	$events:=[]
	$nodes:=This:C1470._nodes
	
	For each ($node; $nodes)
		If ($node.transitions#Null:C1517)
			For each ($eventType; $node.transitions)
				If ($events.indexOf($eventType)<0)
					$events.push($eventType)
				End if 
			End for each 
		End if 
	End for each 
	
	return $events
	
/*
Gets meta data from all active state nodes
*/
Function get meta() : Object
	var $allMeta : Object
	var $node : cs:C1710.StateNode
	
	$allMeta:=New object:C1471
	
	For each ($node; This:C1470._nodes)
		If ($node.meta#Null:C1517)
			$allMeta[$node.id]:=$node.meta
		End if 
	End for each 
	
	return $allMeta
	
/*
Checks if snapshot is in an error state
*/
Function get hasError() : Boolean
	return (This:C1470.status="error")
	
/*
Gets a string path representation of the state value
*/
Function toStrings() : Collection
	return This:C1470._valueToStrings(This:C1470.value)
	
/*
Converts state value to string paths recursively
*/
Function _valueToStrings($value : Variant) : Collection
	var $strings : Collection
	var $key : Text
	var $childStrings : Collection
	var $childString : Text
	
	$strings:=[]
	
	Case of 
		: (Value type:C1509($value)=Is text:K8:3)
			$strings.push($value)
			
		: (Value type:C1509($value)=Is object:K8:27)
			For each ($key; $value)
				$childStrings:=This:C1470._valueToStrings($value[$key])
				For each ($childString; $childStrings)
					$strings.push($key+"."+$childString)
				End for each 
			End for each 
	End case 
	
	return $strings
	
/*
Serializes snapshot for persistence
	
@returns {Object} - Persisted snapshot data
*/
Function toJSON() : Object
	var $json : Object
	
	$json:=New object:C1471
	$json.value:=This:C1470.value
	$json.context:=This:C1470.context
	$json.status:=This:C1470.status
	$json.output:=This:C1470.output
	$json.error:=This:C1470.error
	$json.tags:=This:C1470.tags
	
	return $json
	
/*
Creates a clone of this snapshot with optional overrides
*/
Function clone($overrides : Object) : cs:C1710.MachineSnapshot
	var $config : Object
	
	$config:=New object:C1471(\
		"value"; Choose:C955($overrides.value#Null:C1517; $overrides.value; This:C1470.value); \
		"context"; Choose:C955($overrides.context#Null:C1517; $overrides.context; OB Copy:C1225(This:C1470.context)); \
		"status"; Choose:C955($overrides.status#Null:C1517; $overrides.status; This:C1470.status); \
		"machine"; This:C1470.machine; \
		"output"; Choose:C955($overrides.output#Null:C1517; $overrides.output; This:C1470.output); \
		"error"; Choose:C955($overrides.error#Null:C1517; $overrides.error; This:C1470.error); \
		"historyValue"; Choose:C955($overrides.historyValue#Null:C1517; $overrides.historyValue; This:C1470.historyValue); \
		"children"; Choose:C955($overrides.children#Null:C1517; $overrides.children; This:C1470.children); \
		"_nodes"; Choose:C955($overrides._nodes#Null:C1517; $overrides._nodes; This:C1470._nodes)\
		)
	
	return cs:C1710.MachineSnapshot.new($config)
	
	