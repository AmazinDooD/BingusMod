# hi :3
# alterations are marked with comments starting with "PATCH: "

extends Level
class_name EditorLevel
var levelPath = "E:/GodotExport/ucgLevels/eviltrash.json"
var worldPath = ""
var editor: levelEditor
var test = false
var song = 0
var customSong = false
var customSongName = ""
@onready var dec = preload("res://assetsNEW/scenes/objects/misc/editorDeco.tscn")
var mods = ""
var pthruishere
var customIsNew: = false

# PATCH: load BingusMod class and setup my variables :P
@onready var _BingusMod = preload("res://mods/bingusmod/bingusmod.gd")
@onready var BingusMod = _BingusMod.new()
@onready var bconf = BingusMod.load_config()

# PATCH: playtest panning
func _input(event):
	if event is InputEventMouseMotion && \
	test && \
	bconf.playtest_panning && \
	Input.is_action_pressed("middleMouse") && \
	BingusMod.pan_key_down() && \
	!$WinConfetti.visible:
		camera.position += event.relative * -1

func win():
	super ()
	var master = get_parent().get_parent()
	if test:
		master = get_parent()
	master.update_mods(Modifiers.new())
	if get_parent() is customPThru:
		master = get_parent().get_parent()
		var pthru = get_parent()
		var key = master.customWorldName + master.customLevelNames[pthru.levelNum]
		if pthru.saveData.has(key + "_score"):
			if pthru.saveData.get(key + "_score") > final_score:
				pthru.save()
				return
		pthru.saveData.set(key + "_time", time_elapsed)
		pthru.saveData.set(key + "_strokes", strokes)
		pthru.saveData.set(key + "_score", final_score)
		pthru.saveData.set(key + "_rank1", rank_reqs[5])
		pthru.save()


func _physics_process(delta: float) -> void :
	super (delta)
	if test and Input.is_action_just_pressed(&"Restart"):
		escape(false)
		editor.playtestLevel()


func _ready():
	if Engine.is_editor_hint():
		return
	loadLevel()
	if test:
		var master = get_parent()
		master.play_music(song)
	else:
		var master = get_parent().get_parent()
		if master.current_song_ID != song || customIsNew:
			master.play_music(song)

	HUD.visible = true
	switch()
	camera.zoom = Vector2(256.0 / bounds, 256.0 / bounds)
	if mirror_level:
		camera.zoom.x = - camera.zoom.x
	camera.position.x = -128 / camera.zoom.x
	HUD.nameAnim.play("stagenameslide")
	HUD.strokes.text = "[rainbow freq=" + str(HUD.strokes_modulate) + " sat=" + str(HUD.strokes_modulate) + " val=1.0]" + tr("GAME_Strokes").format({"stroke": str(strokes)})
	HUD.levelB.text = tr("GAME_LevelBonus").format({"bonus": str(level_bonus)})
	if win_confetti != null:
		win_confetti.visible = false
		win_confetti.scale = Vector2(bounds / 256.0, bounds / 256.0)
	HUD.par.text = str(par)
	if mode == MODES.NORMAL and !test_mode and mod_data.mods["buddy"]:
		var buddy = load("uid://cmcwv7k1ov0ln").instantiate() as LittleBuddy
		buddy.player = player
		buddy.global_position = player.global_position
		add_child(buddy)
	if mod_data.mods["missiles"]:
		var attacker: = load("uid://qk5gw874w6vh").instantiate() as MissileAttacker
		attacker.level = self
		attacker.player = player
		attacker.global_position = player.global_position
		add_child(attacker)
	if mod_data.mods["E-bort"]:
		for i in 25:
			bort_spawn()
	if mod_data.mods["E-bees"]:
		for i in 20:
			var bee: = load("uid://dle0ue7p82122").instantiate() as Bee

			bee.global_position = Vector2(randf_range(0, 768), randf_range(0, 512))
			HUD.add_child(bee)
			if i == 0:
				bee.buzz()




func loadLevel():
	var master = get_parent().get_parent()
	if test:
		master = get_parent()
	master.update_mods(Modifiers.new())
	var path = levelPath
	var save_file = FileAccess.open(path, FileAccess.READ)
	if save_file == null:
		escape()
		return
	var json_string = save_file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		push_error("JSON parse error ", json.get_error_message(), " on line ", json.get_error_line())
		return
	var saveData = json.get_data()
	if "song" in saveData:

		if master is Master:
			song = Master.Music.W0
			if saveData.song == 0:
				song = Master.Music.W0
			elif saveData.song == 1:
				song = Master.Music.W1
			elif saveData.song == 2:
				song = Master.Music.W2
			elif saveData.song == 3:
				song = Master.Music.W3
			elif saveData.song == 4:
				song = Master.Music.W4
			elif saveData.song == 5:
				if "customSongName" in saveData:
					if master.customSong != saveData.customSongName:
						customIsNew = true
					master.customSong = saveData.customSongName
					song = Master.Music.CUSTOM
					if "bpm" in saveData:
						master.customSongBpm = saveData.bpm
					if "loopPoint" in saveData:
						master.customSongLoopPoint = saveData.loopPoint

	if "levelName" in saveData:
		HUD.lvlName.text = saveData.world + "-" + saveData.id + ": " + "" + saveData.levelName
	if "levelAuthor" in saveData:
		HUD.lvlAuthor.text = "Level by: " + saveData.levelAuthor
	if "rank1" in saveData:
		rank_reqs[5] = int(saveData.rank1)
	if "rank2" in saveData:
		rank_reqs[4] = int(saveData.rank2)
	if "rank3" in saveData:
		rank_reqs[3] = int(saveData.rank3)
	if "rank4" in saveData:
		rank_reqs[2] = int(saveData.rank4)
	if "levelBounds" in saveData:
		bounds = saveData.levelBounds
		$tiles.position += Vector2( - bounds / 2, 0)
		$switchtiles1.position += Vector2( - bounds / 2, 0)
		$switchtiles2.position += Vector2( - bounds / 2, 0)
		$switchtiles3.position += Vector2( - bounds / 2, 0)
		$switchtiles4.position += Vector2( - bounds / 2, 0)
		$dogtiles.position += Vector2( - bounds / 2, 0)
	if "par" in saveData:
		par = saveData.par
	if "time" in saveData:
		on_time = saveData.time
	if "light" in saveData:
		$CanvasModulate.color = colorify(saveData.light)


	if "bg" in saveData:
		$editorFloor.texture = $bgSelect.get_item_icon(saveData.bg)
	if "tiles" in saveData:
		for i in saveData.tiles:
			$tiles.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
	if "switchTiles1" in saveData:
		if saveData.switchTiles1.size() != 0:
			switch_tiles.append($switchtiles1)
			for i in saveData.switchTiles1:
				$switchtiles1.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
	if "switchTiles2" in saveData:
		if saveData.switchTiles2.size() != 0:
			switch_tiles.append($switchtiles2)
			for i in saveData.switchTiles2:
				$switchtiles2.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
	if "switchTiles3" in saveData:
		if saveData.switchTiles3.size() != 0:
			switch_tiles.append($switchtiles3)
			for i in saveData.switchTiles3:
				$switchtiles3.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
	if "switchTiles4" in saveData:
		if saveData.switchTiles4.size() != 0:
			switch_tiles.append($switchtiles4)
			for i in saveData.switchTiles4:
				$switchtiles4.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
	if "dogtiles" in saveData:
		if saveData.dogtiles.size() != 0:
			for i in saveData.dogtiles:
				$dogtiles.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
	if "tBright" in saveData:
		$tiles.material.set("shader_parameter/HighShade", colorify(saveData.tBright))
	if "tNormal" in saveData:
		$tiles.material.set("shader_parameter/MidShade", colorify(saveData.tNormal))
	if "tDark" in saveData:
		$tiles.material.set("shader_parameter/LowShade", colorify(saveData.tDark))
	if "tExtra" in saveData:
		$tiles.material.set("shader_parameter/ExtraShade", colorify(saveData.tExtra))
	if "mods" in saveData:
		mods = saveData.mods
	$tiles.tile_set = $tiles.tile_set.duplicate()
	$switchtiles1.tile_set = $switchtiles1.tile_set.duplicate()
	$switchtiles2.tile_set = $switchtiles2.tile_set.duplicate()
	$switchtiles3.tile_set = $switchtiles3.tile_set.duplicate()
	$switchtiles4.tile_set = $switchtiles4.tile_set.duplicate()
	$dogtiles.tile_set = $dogtiles.tile_set.duplicate()

	if "customtiles" in saveData:
		var t = load_image(path.get_base_dir() + "/" + saveData.customtiles)
		if t != null:
			$tiles.tile_set.get_source(1).texture = t
	if "switch1customtiles" in saveData:
		var t = load_image(path.get_base_dir() + "/" + saveData.switch1customtiles)
		if t != null:
			$switchtiles1.tile_set.get_source(1).texture = t
	if "switch2customtiles" in saveData:
		var t = load_image(path.get_base_dir() + "/" + saveData.switch2customtiles)
		if t != null:
			$switchtiles2.tile_set.get_source(1).texture = t
	if "switch3customtiles" in saveData:
		var t = load_image(path.get_base_dir() + "/" + saveData.switch3customtiles)
		if t != null:
			$switchtiles3.tile_set.get_source(1).texture = t
	if "switch4customtiles" in saveData:
		var t = load_image(path.get_base_dir() + "/" + saveData.switch4customtiles)
		if t != null:
			$switchtiles4.tile_set.get_source(1).texture = t
	if "dogcustomtiles" in saveData:
		var t = load_image(path.get_base_dir() + "/" + saveData.dogcustomtiles)
		if t != null:
			$HUD / tabs / tilesTab / tilesPicker.tile_set.get_source(1).texture = t
			$switchtiles1.tile_set.get_source(1).texture = t
	if "deco" in saveData:
		for i in saveData.deco:
			var d = dec.instantiate()
			add_child(d)
			d.position = fvectorify(i[0]) + Vector2( - bounds / 2, 0)
			d.scale = fvectorify(i[1])
			d.rotation = float(i[2])
			d.z_index = int(i[3])
			d.sprite.frame = int(i[4])
			d.animSpeed = float(i[5])
			d.sprite.hframes = int(i[6])
			d.sprite.vframes = int(i[7])
			d.collision = bool(i[8])
			if i[9] != null:
				d.sprite.texture = load(i[9])
			if i.size() > 10:
				d.imageFileName = String(i[10])
			d.levelPath = levelPath.get_base_dir()
	if "nodes" in saveData:
		for i in saveData.nodes:
			if load(i[4]) == load("res://assetsNEW/scenes/objects/player/player.tscn"):
				player.global_position = fvectorify(i[0]) + Vector2( - bounds / 2, 0)
				player.scale = fvectorify(i[1])
				player.modulate = colorify(i[2])
				continue
			var d = load(i[4]).instantiate()
			if i[5] != "sand":
				var tempVars = []
				var tempVa = []
			d.add_to_group("editorLevel")
			if d.get("level") != null:
				d.level = self
			var carp = false
			d.position = fvectorify(i[0]) + Vector2( - bounds / 2, 0)
			d.scale = fvectorify(i[1])
			d.modulate = colorify(i[2])
			if d is Ghost:
				d.z_index = 5
			if i[5] != "sand":
				for j in i[3].keys():
					if i[3].get(j) != null:
						if j != "color":
							d.set(j, i[3].get(j))
						else:
							d.set(j, colorify(i[3].get(j)))
			else:
				carp = true
			add_child(d)
			d.modulate = colorify(i[2])
			if carp:
				var res = []
				for a in i[3].rsplit("("):
					res.append(fvectorify(a))
				res.remove_at(0)
				d.polygon.polygon = res
				d.deco = int(i[6])
	# PATCH: run level script
	if "levelScript" in saveData:
		var file = levelPath.get_base_dir().path_join(saveData.levelScript)
		if FileAccess.file_exists(file):
			var levelfile = path.get_file()
			if bconf.level_scripts:
				var ThisLevelScript = ResourceLoader.load(file, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
				
				if !ThisLevelScript:
					push_error("couldn't load level "+levelfile+"'s script")
				else:
					var instance = ThisLevelScript.new() as LevelScript

					if !instance:
						push_error(levelfile+"'s script doesn't extend LevelScript")
					else:
						instance.set_name("levelScript")
						add_child(instance)
						print("level "+levelfile+" has run a script")
			else:
				print("level "+levelfile+" has a script, but scripts are disabled")
		else:
			print("[BingusMod] That script's NOTHING! Go fuck yourself!")
	
	var rmods = Modifiers.new()
	for i in mods.split(","):
		if rmods.mods.has(i.replace(" ", "").to_lower()):
			rmods.mods.set(i.replace(" ", "").to_lower(), true)
	mod_data = rmods
	if get_parent() is customPThru:
		var pthru: customPThru = get_parent()
		pthru.mod_data = rmods
	master.update_mods(rmods)


func vectorify(str: String):
	var a = 0
	var b = 0
	str = str.replace("(", "")
	str = str.replace(")", "")
	a = str.get_slice(",", 0)
	b = str.get_slice(",", 1)
	return Vector2i(int(a), int(b))

func fvectorify(str: String):
	var a = 0
	var b = 0
	str = str.replace("(", "")
	str = str.replace(")", "")
	a = str.get_slice(",", 0)
	b = str.get_slice(",", 1)
	return Vector2(float(a), float(b))

func colorify(str: String):
	var a = 0
	var b = 0
	var c = 0
	var d = 0
	str = str.replacen("(", "")
	str = str.replacen(")", "")
	a = str.get_slice(",", 0)
	b = str.get_slice(",", 1)
	c = str.get_slice(",", 2)
	d = str.get_slice(",", 3)
	return Color(float(a), float(b), float(c), float(d))

func _process(delta: float) -> void :
	if level_active:
		time_elapsed += delta
		HUD.time.text = Utils.format_seconds(time_elapsed)
		HUD.timeMil.text = Utils.format_seconds_mil(time_elapsed)
		if time_elapsed > on_time + 25:
			HUD.time.modulate = Color(1, 0, 0, 1)
		elif time_elapsed >= on_time:
			HUD.time.modulate = Color(1, 1, 0, 1)
		else:
			HUD.time.modulate = Color(0, 1, 0, 1)
		HUD.timeMil.modulate = HUD.time.modulate
	if Input.is_action_just_pressed("escape") && test:
		escape()
	# PATCH: playtest zooming
	if test && \
	Input.is_action_pressed("ctrl") && \
	bconf.playtest_zooming && \
	!$WinConfetti.visible:
		if Input.is_action_just_released("scrollDown") && camera.zoom > Vector2(0.1, 0.1):
			camera.zoom -= Vector2(0.1, 0.1)
		if Input.is_action_just_released("scrollUp") && camera.zoom < Vector2(3.9, 3.9):
			camera.zoom += Vector2(0.1, 0.1)

func escape(muteMusic: = true):
	if editor == null:
		return
	var master = get_parent()
	if muteMusic && test:
		master.play_music(Master.Music.NONE)
	master.update_mods(Modifiers.new())
	editor.fullui.test_mode = false
	editor.position = Vector2(0, 0)
	editor.show()
	editor.hud.visible = true
	editor.process_mode = Node.PROCESS_MODE_INHERIT
	editor.camera.enabled = true
	queue_free()


func load_image(path: String):	
	var image = Image.load_from_file(path)
	var texture = ImageTexture.create_from_image(image)
	return texture
