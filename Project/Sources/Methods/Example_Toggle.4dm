//%attributes = {}
/*
EXAMPLE: Toggle Machine
Simplest possible state machine - two states toggling back and forth

Run this method to see a simple toggle in action.
*/

var $machine : cs:C1710.StateMachine:=cs:C1710.State.me.createMachine({\
id: "toggle"; \
initial: "inactive"; \
states: {\
inactive: {\
on: {TOGGLE: "active"}\
}; \
active: {\
on: {TOGGLE: "inactive"}\
}\
}\
})

var $actor:=cs:C1710.State.me.createActor($machine)
$actor.start()

ALERT:C41("Toggle state: "+String:C10($actor.value))  // inactive

$actor.send("TOGGLE")
ALERT:C41("Toggle state: "+String:C10($actor.value))  // active

$actor.send("TOGGLE")
ALERT:C41("Toggle state: "+String:C10($actor.value))  // inactive

$actor.send("TOGGLE")
ALERT:C41("Toggle state: "+String:C10($actor.value))  // active
