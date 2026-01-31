//%attributes = {}
/*
EXAMPLE: Form Validation with Guards
Demonstrates conditional transitions using guards

Run this method to see form validation with guards in action.
*/

var $machine : cs:C1710.StateMachine:=cs:C1710.State.me.createMachine({\
id: "form"; \
initial: "editing"; \
context: {\
email: ""; \
password: ""; \
errors: []\
}; \
states: {\
editing: {\
on: {\
UPDATE_EMAIL: {\
actions: cs:C1710.Actions.me.assign({\
email: Formula:C1597($1.event.value)\
})\
}; \
UPDATE_PASSWORD: {\
actions: cs:C1710.Actions.me.assign({\
password: Formula:C1597($1.event.value)\
})\
}; \
SUBMIT: [\
{target: "submitted"; guard: "isValid"}; \
{target: "error"}\
]\
}\
}; \
submitted: {\
type: "final"\
}; \
error: {\
on: {\
RETRY: "editing"\
}\
}\
}\
})

// Provide guard implementation
$machine:=$machine.provide({\
guards: {\
isValid: Formula:C1597((Length:C16(String:C10($1.context.email))>0) && (Length:C16(String:C10($1.context.password))>=8))\
}\
})

var $actor:=cs:C1710.State.me.createActor($machine)
$actor.start()

// Try to submit with empty fields
$actor.send("SUBMIT")
ALERT:C41("State after empty submit: "+String:C10($actor.value))  // "error"

$actor.send("RETRY")
$actor.send({type: "UPDATE_EMAIL"; value: "user@example.com"})
$actor.send({type: "UPDATE_PASSWORD"; value: "password123"})
$actor.send("SUBMIT")
ALERT:C41("State after valid submit: "+String:C10($actor.value))  // "submitted"
