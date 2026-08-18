extends LevelScript
# ↑ Don't remove this line. ↑

# NOTE: Level scripts are re-run when the level is restarted.

# Called when the script is loaded, like any other node :P
func _ready() -> void:
	print("example level script: loaded")
	
	# Make anything with a pure red modulate kill you when collecting it
	var evilStuff = get_things(FILTER.by_modulate, Color(1.0, 0.0, 0.0))
	for thing: Area2D in evilStuff:
		var obj = thing as Collectible
		if not obj: continue # Object isn't a collectible
		
		# Override old collect function.
		obj.collect = func(body): death()
