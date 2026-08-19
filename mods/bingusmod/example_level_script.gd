extends LevelScript
# ↑ Don't remove this line. ↑

# Note: Level scripts are re-run when the level is restarted.
# Note 2: There's a bunch of cool functions in level_script.gd.

# Called when the script is loaded, like any other node :P
func _ready() -> void:
	print("example level script: loaded")
	
	# Make all collectibles with a pure red modulate kill you when collecting it
	var evilStuff = get_things(FILTER.combine.call([
		FILTER.collectibles_only,
		FILTER.by_modulate,
	]), Color(1.0, 0.0, 0.0))

	for obj: Collectible in evilStuff:
		# Override old collect function. 
		patch_connection(obj, &"body_entered", func(_body): death(), false, [obj.collect])
