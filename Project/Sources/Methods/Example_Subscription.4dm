//%attributes = {}
/*
EXAMPLE: Subscription Pattern
Demonstrates observing state changes with subscribers

Run this method to see how to subscribe to state changes.
*/

var $stateLog:=[]

var $machine : cs:C1710.StateMachine:=cs:C1710.State.me.createMachine({\
id: "steps"; \
initial: "step1"; \
states: {\
step1: {on: {NEXT: "step2"}}; \
step2: {on: {NEXT: "step3"}}; \
step3: {type: "final"}\
}\
})

var $actor:=cs:C1710.State.me.createActor($machine)

// Subscribe to state changes
var $subscription:=$actor.subscribe(Formula:C1597($stateLog.push(String:C10($1.value))))

$actor.start()
$actor.send("NEXT")
$actor.send("NEXT")

ALERT:C41("State history: "+$stateLog.join(" -> "))
// Output: "step1 -> step2 -> step3"

// Clean up subscription
$subscription.unsubscribe()
