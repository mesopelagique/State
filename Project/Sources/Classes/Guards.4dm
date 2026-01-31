/*
Guards - Helper class for creating guard conditions

Guards are conditions that determine whether a transition can be taken.
They receive the current context and event, and return a boolean.

Built-in guard creators:
- and(...guards): All guards must pass
- or(...guards): At least one guard must pass
- not(guard): Inverts a guard
- stateIn(stateValue): Checks if machine is in a specific state

Usage:
var $guard := cs.Guards.me.and("isValid"; "hasPermission")
var $guard := cs.Guards.me.or("isAdmin"; "isOwner")
var $guard := cs.Guards.me.not("isLocked")
var $guard := cs.Guards.me.stateIn("editing.active")
*/

shared singleton Class constructor
	// Singleton pattern for accessing guard creators
	
/*
Creates an AND guard that passes only if all guards pass
	
@param {Collection} $guards - Collection of guards to combine
@returns {Object} - Guard definition
*/
Function and($guards : Collection) : Object
	return {type: "stateand"; guards: $guards}
	
/*
Creates an OR guard that passes if at least one guard passes
	
@param {Collection} $guards - Collection of guards to combine
@returns {Object} - Guard definition
*/
Function or($guards : Collection) : Object
	return {type: "stateor"; guards: $guards}
	
/*
Creates a NOT guard that inverts another guard
	
@param {Variant} $guardToNegate - Guard to negate
@returns {Object} - Guard definition
*/
Function not($guardToNegate : Variant) : Object
	return {type: "statenot"; guard: $guardToNegate}
	
/*
Creates a guard that checks if machine is in a specific state
	
@param {Variant} $stateValue - State value to check
@returns {Object} - Guard definition
*/
Function stateIn($stateValue : Variant) : Object
	return {type: "statestateIn"; stateValue: $stateValue}
	
/*
Creates a named guard reference with optional params
	
@param {Text} $guardName - Name of the guard
@param {Object} $params - Optional parameters
@returns {Object} - Guard definition
*/
Function ref($guardName : Text; $params : Object) : Object
	var $guard : Object:={type: $guardName}
	If ($params#Null)
		$guard.params:=$params
	End if 
	return $guard
	
	
	