class_name LevelScript
extends Node

static var FILTER = {
	by_modulate = func(node, filter): return node.modulate == filter,
	by_visibility = func(node, filter): return node.visible == filter,
	by_properties = func(node, filter):
		for property in filter:
			var pname = property[0]
			var pval = property[1]
			if not node[pname] == pval: return false
		return true,

	## Car/Chuckle/Skull
	baddies_only = func(node, _filter): return node is Baddie,
	## Block/KeyDoor/PrismGate/SwitchBlock
	blocks_only = func(node, _filter): return node is Block,
	## Nuke/SmileyCoin/SmileyRing/SpeedToken/StopToken
	collectibles_only = func(node, _filter): return node is Collectible,
	## Goal (NOT HorseGoal)
	goal_only = func(node, _filter): return node is Goal,
	
	## NOT a filter function. Used to combine multiple filter functions together
	combine = func(funcs):
		return func(node, filter):
			for f in funcs:
				if !f.call(node, filter): return false
			return true
}

func ready_check(name: String) -> bool:
	if !is_node_ready():
		print("[color=red]"+name+"(...) cannot be called before the node is ready")
		return false
	return true

## Returns the contents of a file given a path.
static func read_file(path: String) -> String: return FileAccess.open(path, FileAccess.READ).get_as_text()

## Given a filter function, returns all objects in the current level that
## make this function return true. Most objects are Area2Ds but some aren't, so be careful![br]
## [code]filter[/code] is an optional parameter that gets passed to your conds function.[br]
## This is intented to be used with functions in [code]LevelScript.FILTERS[/code]
func get_things(conds: Callable, filter = null) -> Array[Node2D]:
	if !ready_check("get_things"): return []
	if not (conds.get_argument_count() in [1,2]):
		print("[color=red]get_things(...) was called with callable with an incorrect argument count")
		return []

	var tree := get_tree()
	var nodes := tree.get_nodes_in_group(&"editorLevel")
	var valid: Array[Node2D] = []
	for node in nodes:
		if conds.call(node, filter) == true:
			valid.append(node)

	return valid

## Moves the camera. Wow!
func move_camera(offset: Vector2) -> void:
	if !ready_check("move_camera"): return
	if !$Camera2D:
		print("[color=yellow]Camera object doesn't exist")
		return
	
	$Camera2D.offset += offset

## Sets the player's strokes to a certain amount.
func set_strokes(strokes: int) -> void:
	if !ready_check("set_strokes"): return
	
	get_parent().strokes = strokes

## Returns how many strokes the player has used.[br]
## Returns -1 if the node isn't ready yet.
func get_strokes() -> int:
	if !ready_check("get_strokes"): return -1
	
	return get_parent().strokes

## Adds a number to the player's strokes.[br]
## Use this function instead of calling [code]get_strokes[/code] and [code]set_strokes[/code] separately.
func mod_strokes(mod: int) -> void:
	if !ready_check("mod_strokes"): return
	
	get_parent().strokes += mod

## Instantly WIN the game! /ref
func win():
	if !ready_check("win"): return
	
	get_parent().win()

## Instantly LOSE the game! /ref
func death(type := Level.DEATH_TYPES.WALL_STUCK, cause: Node2D = null):
	if !ready_check("death"): return
	
	get_parent().death(type, cause)

## Injects your own code into a connection.[br]
## [code]obj[/code] should have a signal called [code]signal_name[/code].[br]
## [code]patch[/code] is the function to inject.[br]
## If [code]keep_original[/code] is true, the original connections will not be deleted.[br]
## [code]replacing[/code] is a list of connections to disconnect.
func patch_connection(
	obj,
	signal_name: String,
	patch: Callable,
	keep_original := false,
	replacing: Array[Callable] = [],
):
	var sig := obj[signal_name] as Signal
	if not sig:
		print("[color=red]patching connection failed: object doesn't have signal "+signal_name+", or it isn't a signal[/color]")
		return

	var replace_all := replacing == []
	var connections = sig.get_connections()

	if not keep_original:
		for conn: Dictionary in connections:
			if replace_all || conn.callable in replacing:
				sig.disconnect(conn.callable)
	
	sig.connect(patch)
