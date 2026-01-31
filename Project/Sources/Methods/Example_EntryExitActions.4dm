//%attributes = {}
/*
EXAMPLE: Entry and Exit Actions
Demonstrates state lifecycle hooks

Run this method to see entry and exit actions in action.
*/

var $machine : cs:C1710.StateMachine:=cs:C1710.State.me.createMachine({\
id: "lifecycle"; \
initial: "idle"; \
context: {log: []}; \
states: {\
idle: {\
entry: cs:C1710.Actions.me.assign({\
log: Formula:C1597($1.context.log.concat(["entered idle"]))\
}); \
exit: cs:C1710.Actions.me.assign({\
log: Formula:C1597($1.context.log.concat(["exited idle"]))\
}); \
on: {ACTIVATE: "active"}\
}; \
active: {\
entry: cs:C1710.Actions.me.assign({\
log: Formula:C1597($1.context.log.concat(["entered active"]))\
}); \
exit: cs:C1710.Actions.me.assign({\
log: Formula:C1597($1.context.log.concat(["exited active"]))\
}); \
on: {DEACTIVATE: "idle"}\
}\
}\
})

var $actor:=cs:C1710.State.me.createActor($machine)
$actor.start()

$actor.send("ACTIVATE")
$actor.send("DEACTIVATE")

ALERT:C41("Action log:\n"+$actor.context.log.join("\n"))
/*
Output:
entered idle
exited idle
entered active
exited active
entered idle
*/
