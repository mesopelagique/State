//%attributes = {}
/*
EXAMPLE: Nested States (Hierarchical)
Demonstrates compound states with child states

Run this method to see nested/hierarchical states in action.
*/

var $machine : cs:C1710.StateMachine:=cs:C1710.State.me.createMachine({\
id: "player"; \
initial: "stopped"; \
states: {\
stopped: {\
on: {PLAY: "playing"}\
}; \
playing: {\
initial: "normal"; \
on: {STOP: "stopped"}; \
states: {\
normal: {\
on: {FAST_FORWARD: "fastForward"}\
}; \
fastForward: {\
on: {NORMAL: "normal"}\
}\
}\
}\
}\
})

var $actor : cs:C1710.Actor:=cs:C1710.State.me.createActor($machine)
$actor.start()

ALERT:C41("Initial: "+JSON Stringify:C1217($actor.value))  // "stopped"

$actor.send("PLAY")
ALERT:C41("After PLAY: "+JSON Stringify:C1217($actor.value))  // { playing: "normal" }

$actor.send("FAST_FORWARD")
ALERT:C41("After FAST_FORWARD: "+JSON Stringify:C1217($actor.value))  // { playing: "fastForward" }

$actor.send("NORMAL")
ALERT:C41("After NORMAL: "+JSON Stringify:C1217($actor.value))  // { playing: "normal" }

$actor.send("STOP")
ALERT:C41("After STOP: "+JSON Stringify:C1217($actor.value))  // "stopped"
