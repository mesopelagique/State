//%attributes = {}
/*
EXAMPLE: Fetch Data Pattern
Simulates async data fetching states (idle -> loading -> success/failure)

Run this method to see a data fetching pattern in action.
*/

var $machine : cs:C1710.StateMachine:=cs:C1710.State.me.createMachine({\
id: "fetch"; \
initial: "idle"; \
context: {\
data: Null:C1517; \
error: Null:C1517\
}; \
states: {\
idle: {\
on: {FETCH: "loading"}\
}; \
loading: {\
on: {\
RESOLVE: {\
target: "success"; \
actions: cs:C1710.Actions.me.assign({\
data: Formula:C1597($1.event.data)\
})\
}; \
REJECT: {\
target: "failure"; \
actions: cs:C1710.Actions.me.assign({\
error: Formula:C1597($1.event.error)\
})\
}\
}\
}; \
success: {\
on: {FETCH: "loading"}\
}; \
failure: {\
on: {\
RETRY: "loading"; \
FETCH: "loading"\
}\
}\
}\
})

var $actor:=cs:C1710.State.me.createActor($machine)
$actor.start()

ALERT:C41("Initial state: "+String:C10($actor.value))  // "idle"

// Start fetch
$actor.send("FETCH")
ALERT:C41("State: "+String:C10($actor.value))  // "loading"

// Simulate success
$actor.send({type: "RESOLVE"; data: {items: [1; 2; 3]}})
ALERT:C41("State: "+String:C10($actor.value)+"\nData: "+JSON Stringify:C1217($actor.context.data))
// State: "success", Data: {"items":[1,2,3]}

// Fetch again
$actor.send("FETCH")
ALERT:C41("State: "+String:C10($actor.value))  // "loading"

// Simulate failure
$actor.send({type: "REJECT"; error: "Network error"})
ALERT:C41("State: "+String:C10($actor.value)+"\nError: "+String:C10($actor.context.error))
// State: "failure", Error: "Network error"

// Retry
$actor.send("RETRY")
ALERT:C41("State after retry: "+String:C10($actor.value))  // "loading"
