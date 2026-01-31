/*
Actor - A running instance of a state machine

The Actor is the runtime that:
- Holds the current state (snapshot)
- Processes incoming events
- Manages the event queue/mailbox
- Notifies subscribers of state changes
- Handles start/stop lifecycle

Actors are the only way to "run" a state machine.
The machine itself is just a definition.
*/

property machine : cs:C1710.StateMachine
property logic : cs:C1710.StateMachine
property id : Text
property sessionId : Text
property _processingStatus : Integer
property _snapshot : cs:C1710.MachineSnapshot
property _observers : Collection
property _eventListeners : Object
property _mailbox : Collection
property _isProcessing : Boolean
property _parent : cs:C1710.Actor
property _input : Variant
property systemId : Text

Class constructor($machine : cs:C1710.StateMachine; $options : Object)
	// Store the machine reference
	This:C1470.machine:=$machine
	This:C1470.logic:=$machine  // Alias for compatibility
	
	// Actor identification
	This:C1470.id:=Choose:C955(Length:C16(String:C10($options.id))>0; $options.id; This:C1470._generateId())
	This:C1470.sessionId:=This:C1470._generateId()
	
	// Processing status: 0 = NotStarted, 1 = Running, 2 = Stopped
	This:C1470._processingStatus:=0
	
	// Current snapshot (state)
	This:C1470._snapshot:=Null:C1517
	
	// Subscribers/observers
	This:C1470._observers:=[]
	
	// Event listeners (for emitted events)
	This:C1470._eventListeners:=New object:C1471
	
	// Event queue (mailbox)
	This:C1470._mailbox:=[]
	This:C1470._isProcessing:=False:C215
	
	// Parent actor (if spawned)
	This:C1470._parent:=$options.parent
	
	// Input value
	This:C1470._input:=$options.input
	
	// System ID for registration
	This:C1470.systemId:=$options.systemId
	
	// Initialize snapshot from persisted state or create new
	If ($options.snapshot#Null:C1517)
		This:C1470._snapshot:=$options.snapshot
	Else 
		If ($options.state#Null:C1517)
			This:C1470._snapshot:=$options.state
		Else 
			This:C1470._initState()
		End if 
	End if 
	
/*
Generates a unique ID
*/
Function _generateId() : Text
	return Generate UUID:C1066
	
/*
Initializes the snapshot from the machine
*/
Function _initState()
	This:C1470._snapshot:=This:C1470.machine.getInitialSnapshot(This:C1470._input)
	
/*
Gets the current snapshot (state)
*/
Function getSnapshot() : cs:C1710.MachineSnapshot
	return This:C1470._snapshot
	
/*
Alias for getSnapshot
*/
Function get snapshot() : cs:C1710.MachineSnapshot
	return This:C1470._snapshot
	
/*
Gets the current state value
*/
Function get state() : cs:C1710.MachineSnapshot
	return This:C1470._snapshot
	
/*
Gets the current context
*/
Function get context() : Object
	If (This:C1470._snapshot#Null:C1517)
		return This:C1470._snapshot.context
	End if 
	return New object:C1471
	
/*
Gets the current state value
*/
Function get value() : Variant
	If (This:C1470._snapshot#Null:C1517)
		return This:C1470._snapshot.value
	End if 
	return Null:C1517
	
/*
Gets current status
*/
Function get status() : Text
	Case of 
		: (This:C1470._processingStatus=0)
			return "NotStarted"
		: (This:C1470._processingStatus=1)
			return "Running"
		: (This:C1470._processingStatus=2)
			return "Stopped"
		Else 
			return "Unknown"
	End case 
	
/*
Starts the actor
	
@returns {cs.Actor} - This actor for chaining
*/
Function start() : cs:C1710.Actor
	// Don't start if already running or stopped
	If (This:C1470._processingStatus#0)
		return This:C1470
	End if 
	
	This:C1470._processingStatus:=1
	
	// Execute initial entry actions
	This:C1470._executeInitialActions()
	
	// Notify observers
	This:C1470._notifyObservers()
	
	// Process any deferred events
	This:C1470._processMailbox()
	
	return This:C1470
	
/*
Executes initial entry actions
*/
Function _executeInitialActions()
	var $nodes : Collection
	var $node : cs:C1710.StateNode
	var $action : Variant
	var $newContext : Object
	
	If (This:C1470._snapshot=Null:C1517)
		return 
	End if 
	
	$nodes:=This:C1470._snapshot._nodes
	$newContext:=This:C1470._snapshot.context
	
	If ($nodes=Null:C1517)
		return 
	End if 
	
	// Execute entry actions for all initial state nodes
	For each ($node; $nodes)
		For each ($action; $node.entry)
			$newContext:=This:C1470.machine._executeAction($action; $newContext; New object:C1471("type"; "stateinit"))
		End for each 
	End for each 
	
	// Update snapshot with new context
	This:C1470._snapshot:=cs:C1710.MachineSnapshot.new(New object:C1471(\
		"value"; This:C1470._snapshot.value; \
		"context"; $newContext; \
		"status"; This:C1470._snapshot.status; \
		"machine"; This:C1470.machine\
		))
	This:C1470._snapshot._nodes:=$nodes
	
/*
Stops the actor
	
@returns {cs.Actor} - This actor for chaining
*/
Function stop() : cs:C1710.Actor
	If (This:C1470._processingStatus#1)
		return This:C1470
	End if 
	
	This:C1470._processingStatus:=2
	
	// Execute exit actions for current states
	This:C1470._executeExitActions()
	
	// Clear mailbox
	This:C1470._mailbox:=[]
	
	// Notify observers of completion
	var $observer : Object
	For each ($observer; This:C1470._observers)
		If ($observer.complete#Null:C1517)
			$observer.complete.call($observer)
		End if 
	End for each 
	
	return This:C1470
	
/*
Executes exit actions for current states
*/
Function _executeExitActions()
	var $nodes : Collection
	var $node : cs:C1710.StateNode
	var $action : Variant
	var $i : Integer
	
	If (This:C1470._snapshot=Null:C1517)
		return 
	End if 
	
	$nodes:=This:C1470._snapshot._nodes
	
	If ($nodes=Null:C1517)
		return 
	End if 
	
	// Execute exit actions from deepest to shallowest
	For ($i; $nodes.length-1; 0; -1)
		$node:=$nodes[$i]
		For each ($action; $node.exit)
			This:C1470.machine._executeAction($action; This:C1470._snapshot.context; New object:C1471("type"; "statestop"))
		End for each 
	End for 
	
/*
Sends an event to the actor
	
@param {Variant} $event - Event to send (Text or Object)
@returns {cs.Actor} - This actor for chaining
*/
Function send($event : Variant) : cs:C1710.Actor
	var $eventObj : Object
	
	// Convert to event object if string
	Case of 
		: (Value type:C1509($event)=Is text:K8:3)
			$eventObj:=New object:C1471("type"; $event)
		: (Value type:C1509($event)=Is object:K8:27)
			$eventObj:=$event
		Else 
			return This:C1470
	End case 
	
	// Add to mailbox
	This:C1470._mailbox.push($eventObj)
	
	// Process if running
	If (This:C1470._processingStatus=1)
		This:C1470._processMailbox()
	End if 
	
	return This:C1470
	
/*
Processes events in the mailbox
*/
Function _processMailbox()
	var $event : Object
	var $newSnapshot : cs:C1710.MachineSnapshot
	
	// Prevent re-entrancy
	If (This:C1470._isProcessing)
		return 
	End if 
	
	This:C1470._isProcessing:=True:C214
	
	While ((This:C1470._mailbox.length>0) && (This:C1470._processingStatus=1))
		$event:=This:C1470._mailbox.shift()
		
		// Perform transition
		$newSnapshot:=This:C1470.machine.transition(This:C1470._snapshot; $event)
		
		// Check if state changed
		If ($newSnapshot#This:C1470._snapshot)
			This:C1470._snapshot:=$newSnapshot
			
			// Notify observers
			This:C1470._notifyObservers()
			
			// Process raised events from actions
			This:C1470._processRaisedEvents()
		End if 
		
		// Check for completion
		If (This:C1470._snapshot.status="done")
			This:C1470._processingStatus:=2
			This:C1470._notifyComplete()
		End if 
	End while 
	
	This:C1470._isProcessing:=False:C215
	
/*
Processes events raised by actions
*/
Function _processRaisedEvents()
	var $context : Object
	var $raisedEvents : Collection
	var $event : Variant
	
	$context:=This:C1470._snapshot.context
	
	If ($context._raisedEvents#Null:C1517)
		$raisedEvents:=$context._raisedEvents
		
		// Clear raised events from context
		OB REMOVE:C1226($context; "_raisedEvents")
		
		// Queue raised events
		For each ($event; $raisedEvents)
			If (Value type:C1509($event)=Is text:K8:3)
				This:C1470._mailbox.push(New object:C1471("type"; $event))
			Else 
				If (Value type:C1509($event)=Is object:K8:27)
					This:C1470._mailbox.push($event)
				End if 
			End if 
		End for each 
	End if 
	
/*
Notifies observers of state change
*/
Function _notifyObservers()
	var $observer : Object
	
	For each ($observer; This:C1470._observers)
		If ($observer.next#Null:C1517)
			$observer.next.call($observer; This:C1470._snapshot)
		End if 
	End for each 
	
/*
Notifies observers of completion
*/
Function _notifyComplete()
	var $observer : Object
	
	For each ($observer; This:C1470._observers)
		If ($observer.complete#Null:C1517)
			$observer.complete.call($observer)
		End if 
	End for each 
	
/*
Subscribes to state changes
	
@param {Variant} $observerOrCallback - Observer object or callback function
@returns {Object} - Subscription with unsubscribe method
*/
Function subscribe($observerOrCallback : Variant) : Object
	var $observer : Object
	var $self : cs:C1710.Actor
	
	$self:=This:C1470
	
	// Convert callback to observer object
	Case of 
		: (OB Instance of:C1731($observerOrCallback; 4D:C1709.Function))
			$observer:=New object:C1471("next"; $observerOrCallback)
		: (Value type:C1509($observerOrCallback)=Is object:K8:27)
			$observer:=$observerOrCallback
		Else 
			$observer:=New object:C1471
	End case 
	
	// Add to observers
	This:C1470._observers.push($observer)
	
	// Call immediately with current snapshot
	If (($observer.next#Null:C1517) && (This:C1470._snapshot#Null:C1517))
		$observer.next.call($observer; This:C1470._snapshot)
	End if 
	
	// Return subscription object
	var $subscription:={actor: This:C1470; observer: $observer}
	$subscription.unsubscribe:=Formula:C1597(This:C1470.actor._observers.remove(This:C1470.actor._observers.indexOf(This:C1470.observer)))
	
	return $subscription
	
/*
Adds a listener for emitted events
	
@param {Text} $eventType - Event type to listen for
@param {4D.Function} $handler - Handler function
@returns {Object} - Subscription with unsubscribe method
*/
Function on($eventType : Text; $handler : 4D:C1709.Function) : Object
	var $listeners : Collection
	var $subscription : Object
	
	// Get or create listeners collection for this event type
	If (This:C1470._eventListeners[$eventType]=Null:C1517)
		This:C1470._eventListeners[$eventType]:=[]
	End if 
	
	$listeners:=This:C1470._eventListeners[$eventType]
	$listeners.push($handler)
	
	// Return subscription
	$subscription:=New object:C1471
	$subscription.unsubscribe:=Formula:C1597($listeners.remove($listeners.indexOf($handler)))
	
	return $subscription
	
/*
Emits an event to listeners
	
@param {Object} $event - Event to emit
*/
Function emit($event : Object)
	var $listeners : Collection
	var $handler : 4D:C1709.Function
	var $eventType : Text
	
	$eventType:=$event.type
	
	// Call specific listeners
	If (This:C1470._eventListeners[$eventType]#Null:C1517)
		$listeners:=This:C1470._eventListeners[$eventType]
		For each ($handler; $listeners)
			$handler.call(Null:C1517; $event)
		End for each 
	End if 
	
	// Call wildcard listeners
	If (This:C1470._eventListeners["*"]#Null:C1517)
		$listeners:=This:C1470._eventListeners["*"]
		For each ($handler; $listeners)
			$handler.call(Null:C1517; $event)
		End for each 
	End if 
	
/*
Checks if actor matches a given state
	
@param {Variant} $stateValue - State value to match
@returns {Boolean}
*/
Function matches($stateValue : Variant) : Boolean
	return cs:C1710.State.me.matchesState(This:C1470._snapshot.value; $stateValue)
	
/*
Gets persisted snapshot for serialization
*/
Function getPersistedSnapshot() : Object
	var $persisted : Object
	
	$persisted:=New object:C1471
	$persisted.value:=This:C1470._snapshot.value
	$persisted.context:=This:C1470._snapshot.context
	$persisted.status:=This:C1470._snapshot.status
	
	return $persisted
	
/*
Converts actor to a Promise that resolves when machine reaches final state
Note: 4D doesn't have native Promises, so this returns a polling object
*/
Function toPromise() : Object
	var $promise : Object
	var $self : cs:C1710.Actor
	
	$self:=This:C1470
	
	$promise:=New object:C1471
	$promise.actor:=This:C1470
	
	// Poll method to check completion
	$promise.isDone:=Formula:C1597($self._snapshot.status="done")
	$promise.getOutput:=Formula:C1597($self._snapshot.output)
	
	return $promise
	
/*
JSON representation
*/
Function toJSON() : Object
	var $json : Object
	
	$json:=New object:C1471
	$json.id:=This:C1470.id
	$json.sessionId:=This:C1470.sessionId
	$json.status:=This:C1470.status
	$json.snapshot:=This:C1470._snapshot
	
	return $json
	
	