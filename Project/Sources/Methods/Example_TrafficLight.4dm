//%attributes = {}
/*
EXAMPLE: Traffic Light Machine
A simple state machine with three states

Run this method to see a traffic light state machine in action.
*/

// Create the machine
var $machine : cs:C1710.StateMachine:=cs:C1710.State.me.createMachine({\
id: "trafficLight"; \
initial: "green"; \
states: {\
green: {\
on: {TIMER: {target: "yellow"}}\
}; \
yellow: {\
on: {TIMER: {target: "red"}}\
}; \
red: {\
on: {TIMER: {target: "green"}}\
}\
}\
})

// Create and start the actor
var $actor:=cs:C1710.State.me.createActor($machine)
$actor.start()

// Current state: "green"
ALERT:C41("Current state: "+String:C10($actor.value))

// Send TIMER event
$actor.send("TIMER")
ALERT:C41("After TIMER: "+String:C10($actor.value))  // "yellow"

$actor.send("TIMER")
ALERT:C41("After TIMER: "+String:C10($actor.value))  // "red"

$actor.send("TIMER")
ALERT:C41("After TIMER: "+String:C10($actor.value))  // "green"
