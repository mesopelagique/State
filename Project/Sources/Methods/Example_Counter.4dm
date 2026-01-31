//%attributes = {}
/*
EXAMPLE: Counter Machine with Context
Demonstrates context management and actions

Run this method to see a counter with INCREMENT, DECREMENT, and RESET.
*/

var $machine : cs:C1710.StateMachine:=cs:C1710.State.me.createMachine({\
id: "counter"; \
initial: "active"; \
context: {count: 0}; \
states: {\
active: {\
on: {\
INCREMENT: {\
actions: cs:C1710.Actions.me.assign({\
count: Formula:C1597($1.context.count+1)\
})\
}; \
DECREMENT: {\
actions: cs:C1710.Actions.me.assign({\
count: Formula:C1597($1.context.count-1)\
})\
}; \
RESET: {\
actions: cs:C1710.Actions.me.assign({count: 0})\
}\
}\
}\
}\
})

var $actor : cs:C1710.Actor:=cs:C1710.State.me.createActor($machine)
$actor.start()

ALERT:C41("Initial count: "+String:C10($actor.context.count))  // 0

$actor.send("INCREMENT")
$actor.send("INCREMENT")
$actor.send("INCREMENT")
ALERT:C41("After 3 increments: "+String:C10($actor.context.count))  // 3

$actor.send("DECREMENT")
ALERT:C41("After decrement: "+String:C10($actor.context.count))  // 2

$actor.send("RESET")
ALERT:C41("After reset: "+String:C10($actor.context.count))  // 0
