# State - Finite State Machine Library for 4D

A comprehensive implementation of finite state machines for 4D, inspired by modern state management patterns.

## Features

- **State Machine Creation** - Define states, transitions, and events
- **Hierarchical States** - Nested/compound states for complex workflows
- **Guards** - Conditional transitions based on context or events
- **Actions** - Entry, exit, and transition actions
- **Context Management** - Maintain and update data throughout the machine lifecycle
- **Actor Model** - Run machines with subscriptions and event handling
- **Type Safety** - Full 4D class-based implementation

## Installation

Copy the `Sources/Classes` folder into your 4D project.

## Quick Start

### Simple Toggle Machine

```4d
var $machine : cs.state.StateMachine:=cs.state.State.me.createMachine({\
    id: "toggle"; \
    initial: "inactive"; \
    states: {\
        inactive: {on: {TOGGLE: "active"}}; \
        active: {on: {TOGGLE: "inactive"}}\
    }\
})

var $actor : cs.state.Actor:=cs.state.State.me.createActor($machine)
$actor.start()

ALERT($actor.value)  // "inactive"

$actor.send("TOGGLE")
ALERT($actor.value)  // "active"
```

### Counter with Context

```4d
var $machine : cs.state.StateMachine:=cs.state.State.me.createMachine({\
    id: "counter"; \
    initial: "active"; \
    context: {count: 0}; \
    states: {\
        active: {\
            on: {\
                INCREMENT: {\
                    actions: cs.state.Actions.me.assign({count: Formula($1.context.count+1)})\
                }; \
                DECREMENT: {\
                    actions: cs.state.Actions.me.assign({count: Formula($1.context.count-1)})\
                }; \
                RESET: {\
                    actions: cs.state.Actions.me.assign({count: 0})\
                }\
            }\
        }\
    }\
})

var $actor : cs.state.Actor:=cs.state.State.me.createActor($machine)
$actor.start()

$actor.send("INCREMENT")
$actor.send("INCREMENT")
ALERT(String($actor.context.count))  // 2
```

### Traffic Light with Transitions

```4d
var $machine : cs.state.StateMachine:=cs.state.State.me.createMachine({\
    id: "trafficLight"; \
    initial: "green"; \
    states: {\
        green: {on: {TIMER: {target: "yellow"}}}; \
        yellow: {on: {TIMER: {target: "red"}}}; \
        red: {on: {TIMER: {target: "green"}}}\
    }\
})

var $actor : cs.state.Actor:=cs.state.State.me.createActor($machine)
$actor.start()

$actor.send("TIMER")  // green -> yellow
$actor.send("TIMER")  // yellow -> red
$actor.send("TIMER")  // red -> green
```

### Form Validation with Guards

```4d
var $machine : cs.state.StateMachine:=cs.state.State.me.createMachine({\
    id: "form"; \
    initial: "editing"; \
    context: {email: ""; password: ""}; \
    states: {\
        editing: {\
            on: {\
                UPDATE_EMAIL: {\
                    actions: cs.state.Actions.me.assign({email: Formula($1.event.value)})\
                }; \
                SUBMIT: {\
                    target: "submitting"; \
                    guard: Formula(Length($1.context.email)>0)\
                }\
            }\
        }; \
        submitting: {\
            on: {SUCCESS: "success"; ERROR: "editing"}\
        }; \
        success: {type: "final"}\
    }\
})
```

### Nested/Hierarchical States

```4d
var $machine : cs.state.StateMachine:=cs.state.State.me.createMachine({\
    id: "player"; \
    initial: "stopped"; \
    states: {\
        stopped: {on: {PLAY: "playing"}}; \
        playing: {\
            initial: "normal"; \
            on: {STOP: "stopped"}; \
            states: {\
                normal: {on: {FAST_FORWARD: "fastForward"}}; \
                fastForward: {on: {NORMAL: "normal"}}\
            }\
        }\
    }\
})
```

### Subscribing to State Changes

```4d
var $actor : cs.state.Actor:=cs.state.State.me.createActor($machine)

var $subscription:=$actor.subscribe(Formula(\
    ALERT("State changed to: "+String($1.value))\
))

$actor.start()
$actor.send("SOME_EVENT")

// Clean up
$subscription.unsubscribe()
```

### Entry and Exit Actions

```4d
var $machine : cs.state.StateMachine:=cs.state.State.me.createMachine({\
    id: "door"; \
    initial: "closed"; \
    states: {\
        closed: {\
            entry: cs.state.Actions.me.log("Door closed"); \
            exit: cs.state.Actions.me.log("Door opening..."); \
            on: {OPEN: "open"}\
        }; \
        open: {\
            entry: cs.state.Actions.me.log("Door is now open"); \
            on: {CLOSE: "closed"}\
        }\
    }\
})
```

## API Reference

### cs.state.State (Main Entry Point)

| Method | Description |
|--------|-------------|
| `cs.state.State.me.createMachine($config)` | Creates a new StateMachine |
| `cs.state.State.me.createActor($machine)` | Creates an Actor to run a machine |

### cs.state.StateMachine

| Property/Method | Description |
|-----------------|-------------|
| `.id` | Machine identifier |
| `.context` | Initial context object |
| `.states` | State definitions |
| `.provide($implementations)` | Provide guard/action implementations |
| `.transition($state; $event)` | Get next state for an event |

### cs.state.Actor

| Property/Method | Description |
|-----------------|-------------|
| `.value` | Current state value |
| `.context` | Current context |
| `.status` | Actor status ("idle", "running", "stopped") |
| `.start()` | Start the actor |
| `.stop()` | Stop the actor |
| `.send($event)` | Send an event (Text or Object) |
| `.subscribe($callback)` | Subscribe to state changes |
| `.getSnapshot()` | Get current MachineSnapshot |

### cs.state.MachineSnapshot

| Property/Method | Description |
|-----------------|-------------|
| `.value` | Current state value |
| `.context` | Current context |
| `.matches($stateValue)` | Check if in a specific state |
| `.hasTag($tag)` | Check if current state has a tag |
| `.can($event)` | Check if event can be handled |

### cs.state.Guards (Helper)

| Method | Description |
|--------|-------------|
| `cs.state.Guards.me.and($guards)` | All guards must pass |
| `cs.state.Guards.me.or($guards)` | At least one guard passes |
| `cs.state.Guards.me.not($guard)` | Invert a guard |
| `cs.state.Guards.me.stateIn($state)` | Check if in specific state |

### cs.state.Actions (Helper)

| Method | Description |
|--------|-------------|
| `cs.state.Actions.me.assign($assignments)` | Update context |
| `cs.state.Actions.me.raise($event)` | Raise an internal event |
| `cs.state.Actions.me.log($message)` | Log a message |
| `cs.state.Actions.me.sendTo($actorRef; $event)` | Send event to another actor |

## State Configuration

Each state can have:

```4d
{
    // Transitions
    on: {
        EVENT_NAME: "targetState";                    // Simple transition
        EVENT_NAME: {target: "state"; guard: ...};   // With guard
        EVENT_NAME: {target: "state"; actions: ...}  // With actions
    };
    
    // Lifecycle
    entry: ...;  // Action(s) on entering state
    exit: ...;   // Action(s) on leaving state
    
    // Nested states
    initial: "childState";
    states: {...};
    
    // Final state
    type: "final";
    
    // Tags
    tags: ["loading"; "async"]
}
```

## Examples

See the `Sources/Methods/` folder for complete examples:

- `Example_Toggle.4dm` - Simple two-state toggle
- `Example_Counter.4dm` - Counter with context
- `Example_TrafficLight.4dm` - Basic state transitions
- `Example_FormValidation.4dm` - Guards and validation
- `Example_NestedStates.4dm` - Hierarchical states
- `Example_Subscription.4dm` - Observing state changes
- `Example_EntryExitActions.4dm` - State lifecycle hooks
- `Example_FetchPattern.4dm` - Async data fetching pattern

## License

MIT

## Credits

Inspired by [XState](https://xstate.js.org/) by David Khourshid.
