# XState for 4D

A comprehensive state machine library for 4D, based on the XState JavaScript library.

## Overview

This library provides a robust implementation of finite state machines (FSM) and statecharts for 4D applications. It enables you to model complex application logic in a clear, predictable, and maintainable way.

## Classes

| Class | Description |
|-------|-------------|
| `XState` | Main entry point with factory methods |
| `StateMachine` | State machine definition |
| `StateNode` | Individual state node |
| `Actor` | Running instance of a machine |
| `MachineSnapshot` | Point-in-time state snapshot |
| `Guards` | Guard condition helpers |
| `Actions` | Action helpers |

## Quick Start

### Simple Toggle Machine

```4d
var $machine : cs.StateMachine
var $actor : cs.Actor

// Define the machine
$machine:=cs.XState.me.createMachine(New object(\
    "id"; "toggle";\
    "initial"; "inactive";\
    "states"; New object(\
        "inactive"; New object("on"; New object("TOGGLE"; "active"));\
        "active"; New object("on"; New object("TOGGLE"; "inactive"))\
    )\
))

// Create and start actor
$actor:=cs.XState.me.createActor($machine)
$actor.start()

// Send events
$actor.send("TOGGLE")  // Now "active"
$actor.send("TOGGLE")  // Now "inactive"
```

### Machine with Context

```4d
$machine:=cs.XState.me.createMachine(New object(\
    "id"; "counter";\
    "initial"; "active";\
    "context"; New object("count"; 0);\
    "states"; New object(\
        "active"; New object(\
            "on"; New object(\
                "INCREMENT"; New object(\
                    "actions"; cs.Actions.assign(New object(\
                        "count"; Formula($1.context.count + 1)\
                    ))\
                )\
            )\
        )\
    )\
))
```

## Machine Configuration

A machine configuration object has the following structure:

```4d
New object(\
    "id"; "machineId";              // Unique identifier
    "initial"; "initialState";      // Initial state name
    "context"; New object(...);     // Initial context data
    "states"; New object(\          // State definitions
        "stateName"; New object(\
            "type"; "atomic";       // Optional: atomic, compound, parallel, final
            "entry"; ...;           // Entry actions
            "exit"; ...;            // Exit actions
            "on"; New object(\      // Event handlers
                "EVENT_NAME"; New object(\
                    "target"; "nextState";\
                    "guard"; "guardName";\
                    "actions"; ...\
                )\
            )\
        )\
    )\
)
```

## State Types

| Type | Description |
|------|-------------|
| `atomic` | Leaf state with no children (default) |
| `compound` | State with nested child states |
| `parallel` | State where all children are active simultaneously |
| `final` | Terminal state |
| `history` | Remembers previous state |

## Actions

### Built-in Actions

```4d
// Assign - Update context
cs.Actions.assign(New object(\
    "propertyName"; newValue;\
    "dynamicProperty"; Formula($1.context.value + $1.event.data)\
))

// Raise - Send event to self
cs.Actions.raise("EVENT_NAME")

// Log - Log a message
cs.Actions.log("Message")
cs.Actions.log(Formula("Count: " + String($1.context.count)))

// SendTo - Send event to another actor
cs.Actions.sendTo($actorRef; "EVENT")

// SendParent - Send event to parent actor
cs.Actions.sendParent("CHILD_DONE")

// Stop - Stop a spawned actor
cs.Actions.stop($actorRef)
```

### Entry/Exit Actions

```4d
New object(\
    "stateName"; New object(\
        "entry"; cs.Actions.assign(New object("enteredAt"; Current time));\
        "exit"; cs.Actions.log("Leaving state")\
    )\
)
```

## Guards

Guards are conditions that must pass for a transition to occur.

### Built-in Guards

```4d
// AND - All guards must pass
cs.Guards.and(New collection("guard1"; "guard2"))

// OR - At least one guard must pass
cs.Guards.or(New collection("guard1"; "guard2"))

// NOT - Invert a guard
cs.Guards.not("guardName")

// StateIn - Check if in a specific state
cs.Guards.stateIn("parentState.childState")
```

### Conditional Transitions

```4d
New object(\
    "SUBMIT"; New collection(\
        New object("target"; "success"; "guard"; "isValid");\
        New object("target"; "error")  // Fallback
    )\
)
```

### Providing Guard Implementations

```4d
$machine:=$machine.provide(New object(\
    "guards"; New object(\
        "isValid"; Formula(Length(String($1.context.email)) > 0);\
        "hasPermission"; Formula($1.context.user.role = "admin")\
    )\
))
```

## Actor API

### Creating and Starting

```4d
$actor:=cs.XState.me.createActor($machine)
$actor.start()
```

### Sending Events

```4d
// Simple event
$actor.send("EVENT_NAME")

// Event with data
$actor.send(New object("type"; "UPDATE"; "data"; someValue))
```

### Reading State

```4d
// Current state value
$actor.value  // Text or Object for nested

// Current context
$actor.context

// Full snapshot
$actor.snapshot

// Check state
$actor.matches("stateName")
```

### Subscribing to Changes

```4d
$subscription:=$actor.subscribe(Formula(\
    ALERT("New state: " + String($1.value))\
))

// Later, unsubscribe
$subscription.unsubscribe
```

### Stopping

```4d
$actor.stop()
```

## Nested/Hierarchical States

```4d
$machine:=cs.XState.me.createMachine(New object(\
    "id"; "player";\
    "initial"; "stopped";\
    "states"; New object(\
        "stopped"; New object(\
            "on"; New object("PLAY"; "playing")\
        );\
        "playing"; New object(\
            "initial"; "normal";\
            "on"; New object("STOP"; "stopped");\
            "states"; New object(\
                "normal"; New object(\
                    "on"; New object("FAST"; "fast")\
                );\
                "fast"; New object(\
                    "on"; New object("NORMAL"; "normal")\
                )\
            )\
        )\
    )\
))
```

## Persistence

### Save State

```4d
$persisted:=$actor.getPersistedSnapshot()
// Store $persisted in database/storage
```

### Restore State

```4d
$actor:=cs.XState.me.createActor($machine; New object(\
    "snapshot"; $persisted\
))
```

## Best Practices

1. **Keep machines small and focused** - One machine per feature
2. **Use context for data** - Keep state names for state, use context for data
3. **Prefer named actions/guards** - Use `provide()` for testability
4. **Model all possible states** - Include error and loading states
5. **Use TypeScript-like documentation** - Add JSDoc comments

## Examples

See `XStateExamples.4dm` for comprehensive examples including:
- Traffic light machine
- Counter with actions
- Form validation with guards
- Nested states
- Subscription pattern
- Entry/exit actions
- Fetch data pattern

## API Reference

### XState Class

| Method | Returns | Description |
|--------|---------|-------------|
| `createMachine($config)` | `cs.StateMachine` | Create a new machine |
| `createActor($machine; $options)` | `cs.Actor` | Create an actor |
| `matchesState($current; $test)` | `Boolean` | Check state match |
| `pathToStateValue($path)` | `Variant` | Convert path to value |

### Actor Class

| Property/Method | Returns | Description |
|-----------------|---------|-------------|
| `.value` | `Variant` | Current state value |
| `.context` | `Object` | Current context |
| `.snapshot` | `cs.MachineSnapshot` | Current snapshot |
| `.status` | `Text` | "NotStarted", "Running", "Stopped" |
| `.start()` | `cs.Actor` | Start the actor |
| `.stop()` | `cs.Actor` | Stop the actor |
| `.send($event)` | `cs.Actor` | Send an event |
| `.subscribe($observer)` | `Object` | Subscribe to changes |
| `.matches($state)` | `Boolean` | Check current state |

### MachineSnapshot Class

| Property/Method | Returns | Description |
|-----------------|---------|-------------|
| `.value` | `Variant` | State value |
| `.context` | `Object` | Context data |
| `.status` | `Text` | "active", "done", "error" |
| `.tags` | `Collection` | Active tags |
| `.matches($state)` | `Boolean` | Check state match |
| `.hasTag($tag)` | `Boolean` | Check for tag |
| `.can($event)` | `Boolean` | Check if event handled |
| `.nextEvents` | `Collection` | Available events |

## License

Based on XState by David Khourshid (MIT License)

