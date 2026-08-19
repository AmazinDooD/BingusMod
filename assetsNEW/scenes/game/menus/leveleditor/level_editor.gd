# hi :3
# alterations are marked with comments starting with "PATCH: "

extends Node2D
class_name levelEditor
@onready var camera: Camera2D = $Camera2D
@onready var tabs: Control = $HUD / tabs
var tempJson = ""
var mods = ""
var mode = 0
var cursorOverSel = false
var modes = {
	INFO = 0, 
	TILES = 1, 
	OBJECTS = 2, 
	DECO = 3, 
	HOTKEYS = 4, 
	CUSTOM = 5
}
var ogSelected
var drag = false
@onready var hud: CanvasLayer = $HUD
var playerPlaced = true
const TEMPPATH = "user://templevel.json"
@export var fullui: EditorUI
var levelPath: = ""
var fileName: = ""
var bounds = 256
@export var objectScenes: Array[EditorObject]
var saving = true
@onready var vanillaDeco = $HUD / tabs / decoTab / ItemList.get_item_count()
var loadedObjectScenes = []
@onready var floor = preload("res://assetsNEW/graphics/stage/deco/W0/bgtiles.png")
@onready var editorFloor: TextureRect = $editorFloor
@onready var cursor: Area2D = $cursorArea
@onready var cursorspr: Sprite2D = $cursorArea / Sprite2D
@onready var decor = preload("res://assetsNEW/scenes/objects/misc/editorDeco.tscn")
var selectedObject
var selectedObjectIdx = 0
var selectedDeco
var selectMode = false:
	set(value):
		if value == true:
			popup("Selection Mode")
		else:
			popup("Placement Mode")
		selectMode = value
@onready var selection: ReferenceRect = $selection
var selectedThing = null
var zoom: = Vector2(0, 0)
@onready var tileLayers = [$tiles, $switchtiles1, $switchtiles2, $switchtiles3, $switchtiles4, $dogtiles]
var selectedTile: = Vector2(0, 0)
var tilemap: TileMapLayer
@onready var exampleVariable: LineEdit = $HUD / tabs / objectsTab / exampleVariable
@onready var exampleEnum: OptionButton = $HUD / tabs / objectsTab / exampleEnum
@onready var exampleColor: ColorPickerButton = $HUD / tabs / objectsTab / exampleColor
@onready var exampleBool: CheckBox = $HUD / tabs / objectsTab / exampleBool
var bg = 0
@onready var dec = preload("res://assetsNEW/scenes/objects/misc/editorDeco.tscn")
var clearPresses = 0
var clearTimer = 0
var selectedDecoIdx = 0
var selectedDecoFilename: = ""
var bpm = 0
@onready var music: AudioStreamPlayer = $Music
var history = []
const maxHistory = 100
var historyPoint = 0
var copiedThing = null
@onready var newPopup = preload("res://assetsNEW/scenes/objects/misc/score_popup.tscn")

# PATCH: load BingusMod class and setup my variables :P
@onready var _BingusMod = preload("res://mods/bingusmod/bingusmod.gd")
@onready var BingusMod = _BingusMod.new()

func _ready() -> void :
	$pickOption.show()
	for i in objectScenes:
		loadedObjectScenes.append(load(i.object))
	var a = 0
	for i in tabs.get_children():
		i.hide()
		if a == 0:
			i.show()
		a += 1


func undo():
	historyPoint -= 1
	if historyPoint < -1:
		return
	if history.size() < historyPoint:
		return
	saving = false
	save(levelPath, history[historyPoint - 1])

func redo():
	historyPoint += 1
	if historyPoint > history.size():
		return
	if history.size() < historyPoint:
		return
	saving = false
	save(levelPath, history[historyPoint - 1])

func updateHistory():
	print("history updated!")
	history.append(saveto(levelPath, true))
	historyPoint = history.size()
	if history.size() > maxHistory:
		history.remove_at(0)
		historyPoint -= 1

func checktest():
	if selectedThing == null:
		return true
	elif selectedThing.global_position.distance_to(get_global_mouse_position()) > getObjRect(selectedThing).x / 2:
		return true
	else:
		return false

func _process(delta: float) -> void :
	if Input.is_action_just_pressed("paste") && copiedThing != null && get_viewport().get_mouse_position().x > 256:
		var c = copiedThing.duplicate()
		c.position = get_global_mouse_position()
		add_child(c, true)
		c.variables = copiedThing.variables.duplicate()
		updateHistory()
	if Input.is_action_just_pressed("undo"):
		undo()
	if Input.is_action_just_pressed("redo"):
		redo()
	if Input.is_action_just_pressed("save"):
		saving = true
		$FileDialog.file_mode = 4

		$FileDialog.visible = true
		$FileDialog.set_current_dir("user://")
	if Input.is_action_just_pressed("load"):
		saving = false
		$FileDialog.file_mode = 0

		$FileDialog.visible = true
		$FileDialog.set_current_dir("user://")
	$scale.modulate.a = lerp($scale.modulate.a, 0.0, 0.01)
	if clearTimer > 0:
		clearTimer -= 1
		if clearTimer == 0:
			clearPresses = 0
			$HUD / TopTab / clear.text = "CLEAR"
	$CanvasModulate.color = $HUD / tabs / levelinfoTab / modulate.color
	if Input.is_action_pressed("ctrl"):
		if Input.is_action_just_released("scrollDown"):
			zoom -= Vector2(0.1, 0.1)
		if Input.is_action_just_released("scrollUp"):
			zoom += Vector2(0.1, 0.1)
		zoom.x = clamp(zoom.x, -0.75, 0.5)
		zoom.y = clamp(zoom.y, -0.75, 0.5)
	$HUD / tabs / tilesTab / tilesPicker.material.set("shader_parameter/HighShade", $HUD / tabs / tilesTab / bright.color)
	$HUD / tabs / tilesTab / tilesPicker.material.set("shader_parameter/MidShade", $HUD / tabs / tilesTab / normal.color)
	$HUD / tabs / tilesTab / tilesPicker.material.set("shader_parameter/LowShade", $HUD / tabs / tilesTab / dark.color)
	$HUD / tabs / tilesTab / tilesPicker.material.set("shader_parameter/ExtraShade", $HUD / tabs / tilesTab / extra.color)
	$tiles.material.set("shader_parameter/HighShade", $HUD / tabs / tilesTab / bright.color)
	$tiles.material.set("shader_parameter/MidShade", $HUD / tabs / tilesTab / normal.color)
	$tiles.material.set("shader_parameter/LowShade", $HUD / tabs / tilesTab / dark.color)
	$tiles.material.set("shader_parameter/ExtraShade", $HUD / tabs / tilesTab / extra.color)

	bounds = $HUD / tabs / levelinfoTab / levelBounds.value
	camera.zoom = (Vector2(256.0 / bounds, 256.0 / bounds)) + zoom
	camera.offset.x = (256 * camera.zoom.x) - 256
	if camera.zoom < Vector2(0.01, 0.01):
		camera.zoom = Vector2(0.01, 0.01)
	$cameraBounds.size = Vector2(bounds * 2, bounds * 2)
	$cameraBounds.position = Vector2( - bounds / 2, - bounds)
	mode = $HUD / tabselector.selected
	# PATCH: allow using ctrl to pan
	if Input.is_action_just_pressed("middleMouse") && !BingusMod.pan_key_down():
		selectMode = !selectMode
	if selectMode == false && selectedThing != null:
		selectedThing = null
	if selectedThing != null && selectMode == true:





		for i in $HUD / tabs / objectsTab / variables.get_children():
			if i is ColorPickerButton:
				selectedThing.modulate = i.color
			if i is CheckBox:
				selectedThing.variables.set(i.name, i.button_pressed)
			if i is LineEdit:
				if i.name.contains("_int"):
					selectedThing.variables.set(i.placeholder_text, int(i.text))
				else:
					selectedThing.variables.set(i.placeholder_text, float(i.text))
			if i is OptionButton:
				selectedThing.variables.set(i.name, i.selected)
		scaler(selectedThing)
		if Input.is_action_just_pressed("delete"):
			selectedThing.queue_free()
			updateHistory()
		if selectedThing != Sprite2D:
			for i in selectedThing.get_children():
				if i is Sprite2D:
					selection.size = i.texture.get_size() * i.global_scale
					selection.size.x /= i.hframes
					selection.size.y /= i.vframes
				if i is AnimatedSprite2D:
					if i.sprite_frames.get_frame_texture(i.animation, 0) != null:
						selection.size = i.sprite_frames.get_frame_texture(i.animation, 0).get_size() * i.global_scale
		else:
			selection.size = selectedThing.texture.get_size() * selectedThing.scale
		selection.global_position = selectedThing.global_position - selection.size / 2
	else:
		if $HUD / tabs / objectsTab / variables.get_children().size() > 0:
			for i in $HUD / tabs / objectsTab / variables.get_children():
				i.queue_free()
		selection.hide()
	if selectMode:
		if selectedThing != null:
			selection.show()
		cursor.global_position = get_global_mouse_position()
		cursor.hide()
		$HUD / TopTab / Label.text = "Mode: SELECTION"
		if Input.is_action_just_pressed("copy") && selectedThing != null:
			copiedThing = selectedThing.duplicate()
		if Input.is_action_just_pressed("escape") && selectedThing != null:
			selectedThing = null
			updateHistory()
		if Input.is_action_just_pressed("Click") && !cursorOverSel && (checktest() || selectedThing == null && get_viewport().get_mouse_position().x > 256):
			var ar = cursor.get_overlapping_areas()
			var bo = cursor.get_overlapping_bodies()
			ar.reverse()
			bo.reverse()
			for i in ar:
				if i.is_in_group("editorObject") && i != selectedThing:
					if !Input.is_action_pressed("alt"):
						selectedThing = i
						selected(selectedThing)
					else:
						if Input.is_action_just_pressed("Click"):
							var dupe = i.duplicate()
							dupe.global_position = get_global_mouse_position()
							add_child(dupe)
							dupe.variables = selectedThing.variables.duplicate()
							selected(dupe)
							selectedThing = dupe
							updateHistory()
					return
			for i in bo:
				if i.is_in_group("editorObject") && i != selectedThing:
					if !Input.is_action_pressed("alt"):
						selectedThing = i
						selected(selectedThing)
					else:
						var dupe = i.duplicate()
						dupe.global_position = get_global_mouse_position()
						add_child(dupe)
						dupe.variables = selectedThing.variables.duplicate()
						updateHistory()
						selected(dupe)
					return
	if !selectMode:
		selection.hide()
		$HUD / TopTab / Label.text = "Mode: PLACEMENT"
		if mode == modes.OBJECTS:
			objects()
		elif mode == modes.DECO:
			deco()
		elif mode == modes.TILES:
			tiles(get_global_mouse_position())
			lastmousepos = get_global_mouse_position()
		else:
			cursor.hide()
	if Input.is_action_just_pressed("RightClickEditor") && mode != modes.TILES:
		var ar = cursor.get_overlapping_areas()
		var bo = cursor.get_overlapping_bodies()
		ar.reverse()
		bo.reverse()
		for i in ar:
			if i.is_in_group("editorObject"):
				i.queue_free()
				return
		for i in bo:
			if i.is_in_group("editorObject"):
				i.queue_free()
				return
		updateHistory()

var lastmousepos = Vector2.ZERO

func selected(thing):
	for i in $HUD / tabs / objectsTab / variables.get_children():
		i.queue_free()
	var obj = 0
	for i in objectScenes.size():
		if thing.is_in_group(str(i)):
			obj = i
	var a = 0
	var coption = exampleColor.duplicate()
	coption.position.x = 96
	coption.position.y = 232 + (9 * a)
	$HUD / tabs / objectsTab / variables.add_child(coption)
	coption.show()
	a += 1
	ogSelected = thing.duplicate()
	if thing is EditorInactive:
		if thing.variables.has("color") && thing.modulate == Color.WHITE:
			coption.color = thing.variables.get("color")
		else:
			coption.color = thing.modulate
	for i in objectScenes[obj].variables:
		if i.isBool:
			var option = exampleBool.duplicate()
			option.position.x = 24
			option.position.y = 232 + (29 * a)
			option.get_child(0).text = i.name + ":"
			$HUD / tabs / objectsTab / variables.add_child(option)
			option.show()
			option.name = i.varname
			if thing.variables.get(i.varname) != null:
				option.button_pressed = thing.variables.get(i.varname)
		elif i.isEnum:
			var option = exampleEnum.duplicate()
			option.position.x = 24
			option.position.y = 232 + (29 * a)
			$HUD / tabs / objectsTab / variables.add_child(option)
			for j in i.enumNames:
				option.add_item(j)
			if thing.variables.get(i.varname) != null:
				option.selected = thing.variables.get(i.varname)
			option.show()
			option.name = i.varname
		else:
			if thing.variables.get(i.varname) == null:
				thing.variables.set(i.varname, 0)
			var option = exampleVariable.duplicate()
			option.position.x = 24
			option.position.y = 232 + (29 * a)
			option.get_child(0).text = i.name + ":"
			$HUD / tabs / objectsTab / variables.add_child(option)
			if thing.variables.get(i.varname) != null:
				option.text = str(thing.variables.get(i.varname))
			option.show()
			option.placeholder_text = i.varname
			if str(float(thing.variables.get(i.varname))) == str(int(thing.variables.get(i.varname))):
				option.name = i.varname + "_int"
			else:
				option.name = i.varname + "_float"
		a += 1

func tiles(mousepos):
	cursor.hide()
	tilemap = tileLayers[$HUD / tabs / tilesTab / layer.selected]
	var off = Vector2i(0, 0)
	if get_viewport().get_mouse_position().x < 256:
		if Input.is_action_just_pressed("Click"):
			var pos = $HUD / tabs / tilesTab / tilesPicker.local_to_map(get_viewport().get_mouse_position()) + Vector2i(-1, -2)
			selectedTile = $HUD / tabs / tilesTab / tilesPicker.get_cell_atlas_coords(pos)
			for i in $HUD / tabs / tilesTab / tilesPicker.get_used_cells():
				if $HUD / tabs / tilesTab / tilesPicker.get_cell_atlas_coords(i) == Vector2i(selectedTile):
					$HUD / tabs / tilesTab / tileSelect.position = i * 16 + Vector2i(18, 40)
					break
		return
	if Input.is_action_pressed("Click"):
		for point in Geometry2D.bresenham_line(Vector2i(lastmousepos), Vector2i(mousepos)):
			tilemap.set_cell(tilemap.local_to_map(point), 1, selectedTile)
		tilemap.set_cell(tilemap.local_to_map(mousepos), 1, selectedTile)
		updateHistory()
	if Input.is_action_pressed("RightClickEditor"):
		tilemap.set_cell(tilemap.local_to_map(mousepos), 1, Vector2i(-1, -1))
		updateHistory()

func getObjRect(selectedThing):
	var siz = Vector2.ZERO
	if selectedThing != Sprite2D:
		for i in selectedThing.get_children():
			if i is Sprite2D:
				siz = i.texture.get_size() * i.global_scale
			if i is AnimatedSprite2D:
				if i.sprite_frames.get_frame_texture(i.animation, 0) != null:
					siz = i.sprite_frames.get_frame_texture(i.animation, 0).get_size() * i.global_scale
	else:
		return selectedThing.texture.get_size() * selectedThing.scale
	return siz

func _input(event):
	if get_viewport().get_mouse_position().x < 256:
		return
	if event is InputEventMouseMotion:
		# PATCH: allow using ctrl to pan
		if Input.is_action_pressed("middleMouse") && BingusMod.pan_key_down():
			camera.position += event.relative * -1
	if event is InputEventMouseMotion || event is InputEventMouseButton:
		if selectedThing != null && selectMode == true:
			if Input.is_action_pressed("alt"):
				if Input.is_action_just_pressed("Click") && get_global_mouse_position().distance_to(selectedThing.global_position) < getObjRect(selectedThing).x / 2:
					var dupe = selectedThing.duplicate()
					dupe.global_position = get_global_mouse_position()
					add_child(dupe, true)
					dupe.variables = selectedThing.variables.duplicate()
					selected(dupe)
					selectedThing = dupe
					updateHistory()
			else:
				if Input.is_action_just_pressed("Click") && get_global_mouse_position().distance_to(selectedThing.global_position) < getObjRect(selectedThing).x / 2:
					drag = true
				if Input.is_action_just_released("Click"):
					drag = false
					updateHistory()
				if drag:
					if Input.is_action_pressed("shift"):
						selectedThing.global_position = get_global_mouse_position()
					else:
						selectedThing.global_position = round(get_global_mouse_position() / 8) * 8



func scaler(something):
	if Input.is_action_pressed("ctrl"):
		return
	if get_viewport().get_mouse_position().x < 256:
		return
	$scale.global_position = something.global_position - Vector2(72, 72) / 2
	if Input.is_action_just_released("scrollDown"):
		$scale.modulate.a = 2.0
		if Input.is_action_pressed("shift"):
			if !Input.is_action_pressed("x"):
				something.scale.x -= 0.01
			if !Input.is_action_pressed("z"):
				something.scale.y -= 0.01
		else:
			if !Input.is_action_pressed("x"):
				something.scale.x -= 0.1
			if !Input.is_action_pressed("z"):
				something.scale.y -= 0.1
		$scale.text = "X " + str(snapped(something.scale.x, 0.1)) + "\nY " + str(snapped(something.scale.y, 0.1))
	if Input.is_action_just_released("scrollUp"):
		$scale.modulate.a = 2.0
		if Input.is_action_pressed("shift"):
			if !Input.is_action_pressed("x"):
				something.scale.x += 0.01
			if !Input.is_action_pressed("z"):
				something.scale.y += 0.01
		else:
			if !Input.is_action_pressed("x"):
				something.scale.x += 0.1
			if !Input.is_action_pressed("z"):
				something.scale.y += 0.1
		$scale.text = "X " + str(snapped(something.scale.x, 0.1)) + "\nY " + str(snapped(something.scale.y, 0.1))


func deco():
	var custom = false
	if selectedDecoIdx > vanillaDeco:
		custom = true
	if selectedDeco == null:
		return
	if get_viewport().get_mouse_position().x < 256:
		return
	cursor.show()
	cursorspr.rotation = 0
	scaler(cursorspr)
	cursorspr.scale.x = clamp(cursorspr.scale.x, 0.001, 100)
	cursorspr.scale.y = clamp(cursorspr.scale.y, 0.001, 100)
	cursor.global_position = round(get_global_mouse_position() / 8) * 8
	if Input.is_action_pressed("shift"):
		cursor.global_position = get_global_mouse_position()
	if Input.is_action_just_pressed("Click"):
		updateHistory()
		var obj = decor.instantiate()
		add_child(obj, true)
		obj.global_position = cursor.global_position
		obj.add_to_group("editorObject")
		obj.sprite.texture = selectedDeco
		obj.sprite.vframes = $HUD / tabs / decoTab / vFrames.value
		obj.sprite.hframes = $HUD / tabs / decoTab / hFrames.value
		obj.scale = cursorspr.scale
		obj.collision = $HUD / tabs / decoTab / collision.button_pressed
		obj.z_index = $"HUD/tabs/decoTab/Z Index".value
		obj.animSpeed = $HUD / tabs / decoTab / speed.value
		obj.sprite.frame = $HUD / tabs / decoTab / frame.value
		obj.imageFileName = selectedDecoFilename


func objects():
	cursor.show()
	var tempVars = []
	var tempVa = []
	cursor.global_position = round(get_global_mouse_position() / 16) * 16
	if get_viewport().get_mouse_position().x < 256:
		return
	if selectedObject == null:
		return
	if Input.is_action_pressed("shift"):
		cursor.global_position = get_global_mouse_position()
	if Input.is_action_just_pressed("Click"):
		var obj = selectedObject.instantiate()
		obj.global_position = cursor.global_position
		obj.add_to_group("editorObject")
		obj.add_to_group(str(selectedObjectIdx))
		var p = false
		if obj is Player:
			p = true
			for i in get_children():
				if i is EditorInactive:
					if i.player == true:
						if Input.is_action_pressed("alt") && Input.is_action_pressed("shift"):
							i.queue_free()
						else:
							popup("Player already exists. Hold ALT+SHIFT to replace.")
							return
		if obj is SmileyCoin:
			obj.modulate = Color("ffee8c")
		if obj is Block && obj.get_child(1) is NinePatchRect && obj is not KeyDoor:
			obj.get_child(1).texture = load("res://assetsNEW/graphics/gimmicks/dblockMonochrome.png")
		if obj is not EditorRunnable:
			for i in obj.get_script().get_script_property_list():
				tempVars.append(i)
				tempVa.append(obj.get(i.get("name")))
			obj.script = load("res://assetsNEW/scenes/game/menus/leveleditor/editorNoScript.gd")
			for i in tempVars.size():
				obj.variables.set(tempVars[i].get("name"), tempVa[i])
		add_child(obj, true)
		if p:
			obj.player = true
		updateHistory()


func _on_tabselector_item_selected(index: int) -> void :
	var a = 0
	for i in tabs.get_children():
		i.hide()
		if a == index:
			i.show()
		a += 1




func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void :
	selectedObject = loadedObjectScenes[index]
	selectedObjectIdx = index
	var a = selectedObject.instantiate()
	for i in a.get_children():
		if i is AnimatedSprite2D:
			cursorspr.texture = i.sprite_frames.get_frame_texture(i.animation, 0)
			cursorspr.scale = i.scale
			cursorspr.rotation = i.rotation
		if i is Sprite2D:
			cursorspr.texture = i.texture
			cursorspr.scale = i.scale
			cursorspr.hframes = i.hframes
			cursorspr.vframes = i.vframes
			cursorspr.rotation = i.rotation
		if index == 0:
			cursorspr.texture = load("res://assetsNEW/graphics/player/costume_canny.png")
			cursorspr.scale = Vector2(0.064, 0.064)
		if index == 2:
			cursorspr.texture = load("res://assetsNEW/graphics/stage/goal/goalhole.png")
			cursorspr.scale = Vector2(0.25, 0.25)



func _on_item_list_item_clicked_deco(index: int, at_position: Vector2, mouse_button_index: int) -> void :
	selectedDeco = $HUD / tabs / decoTab / ItemList.get_item_icon(index)
	selectedDecoIdx = index
	cursorspr.texture = selectedDeco
	cursorspr.scale = Vector2(1, 1)
	if index >= vanillaDeco:
		selectedDecoFilename = $HUD / tabs / decoTab / ItemList.get_item_text(index)
	else:
		selectedDecoFilename = ""

func _on_bg_select_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void :
	floor = $HUD / tabs / levelinfoTab / bgSelect.get_item_icon(index)
	editorFloor.texture = floor
	bg = index


func _on_save_pressed() -> void :
	saving = true
	$FileDialog.file_mode = 4
	$FileDialog.visible = true

func saveto(path: String, returnString: bool = false):
	var saveData = {
		"levelName": $HUD / tabs / levelinfoTab / levelName.text, 
		"levelAuthor": $HUD / tabs / levelinfoTab / levelAuthor.text, 
		"world": $HUD / tabs / levelinfoTab / world.text, 
		"id": $HUD / tabs / levelinfoTab / id.text, 
		"rank1": int($HUD / tabs / levelinfoTab / rankPeak.value), 
		"rank2": int($HUD / tabs / levelinfoTab / rankSwag.value), 
		"rank3": int($HUD / tabs / levelinfoTab / rankOk.value), 
		"rank4": int($HUD / tabs / levelinfoTab / rankErm.value), 
		"levelBounds": $HUD / tabs / levelinfoTab / levelBounds.value, 
		"light": $HUD / tabs / levelinfoTab / modulate.color, 
		"song": $HUD / tabs / levelinfoTab / song.selected, 
		"customSongName": $HUD / tabs / customTab / songName.text, 
		"bg": bg, 
		"tiles": [], 
		"switchTiles1": [], 
		"switchTiles2": [], 
		"switchTiles3": [], 
		"switchTiles4": [], 
		"dogtiles": [], 
		"nodes": [], 
		"deco": [], 
		"tBright": $HUD / tabs / tilesTab / bright.color, 
		"tNormal": $HUD / tabs / tilesTab / normal.color, 
		"tDark": $HUD / tabs / tilesTab / dark.color, 
		"tExtra": $HUD / tabs / tilesTab / extra.color, 
		"par": $HUD / tabs / levelinfoTab / par.value, 
		"time": $HUD / tabs / levelinfoTab / time.value, 
		"bpm": $HUD / tabs / customTab / bpm.value, 
		"loopPoint": $HUD / tabs / customTab / loopoffset.value, 
		"customtiles": $HUD / tabs / customTab / tiles.text, 
		"switch1customtiles": $HUD / tabs / customTab / tiles2.text, 
		"switch2customtiles": $HUD / tabs / customTab / tiles3.text, 
		"switch3customtiles": $HUD / tabs / customTab / tiles4.text, 
		"switch4customtiles": $HUD / tabs / customTab / tiles5.text, 
		"dogcustomtiles": $HUD / tabs / customTab / tiles6.text, 
		"mods": $HUD / tabs / customTab / modifiers.text,
		# PATCH: level scripts
		"levelScript": $HUD / tabs / customTab / levelScript.text,
	}
	for i in get_tree().get_nodes_in_group("editorObject"):
		if i is not editorDeco:
			if i is EditorInactive:
				saveData.get("nodes").append([i.position, i.scale, i.modulate, i.variables, i.scene_file_path, "obj", -1])
			if i is EditorRunnable:
				saveData.get("nodes").append([i.position, i.scale, i.modulate, i.polygon.polygon, i.scene_file_path, "sand", i.deco])
		else:
			if i.sprite.texture != null:
				saveData.get("deco").append([i.position, i.scale, i.rotation, i.z_index, i.sprite.frame, i.animSpeed, i.sprite.hframes, i.sprite.vframes, i.collision, i.sprite.texture.get_path(), i.imageFileName])
			else:
				saveData.get("deco").append([i.position, i.scale, i.rotation, i.z_index, i.sprite.frame, i.animSpeed, i.sprite.hframes, i.sprite.vframes, i.collision, null, i.imageFileName])

	var a = 0
	var layers = ["tiles", "switchTiles1", "switchTiles2", "switchTiles3", "switchTiles4", "dogtiles"]
	for i in tileLayers:
		for iv in i.get_used_cells():
			if layers[a] in saveData:
				saveData.get(layers[a]).append([iv, i.get_cell_atlas_coords(iv)])
		a += 1 
	if returnString:
		return JSON.stringify(saveData)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	var json_string = JSON.stringify(saveData)
	file.store_string(json_string)
	file.close()
	print("saved level!")

func save(path: String, loadFromString: String = ""):
	levelPath = path
	$pickOption.hide()
	if saving:
		if loadFromString == "":
			saveto(path)
		else:
			print_rich("[color=red]why are you saving")
	else:
		for i in tileLayers:
			i.clear()
		for i in get_tree().get_nodes_in_group("editorObject"):
			i.queue_free()
		var save_file = FileAccess.open(path, FileAccess.READ)
		var json_string = save_file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			push_error("JSON parse error ", json.get_error_message(), " on line ", json.get_error_line())
			return
		var saveData = json.get_data()
		if loadFromString != "":
			json.parse(loadFromString)
			saveData = json.get_data()
		if "levelName" in saveData:
			$HUD / tabs / levelinfoTab / levelName.text = saveData.levelName
		if "levelAuthor" in saveData:
			$HUD / tabs / levelinfoTab / levelAuthor.text = saveData.levelAuthor
		if "world" in saveData:
			$HUD / tabs / levelinfoTab / world.text = saveData.world
		if "id" in saveData:
			$HUD / tabs / levelinfoTab / id.text = saveData.id
		if "rank1" in saveData:
			$HUD / tabs / levelinfoTab / rankPeak.value = saveData.rank1
		if "rank2" in saveData:
			$HUD / tabs / levelinfoTab / rankSwag.value = saveData.rank2
		if "rank3" in saveData:
			$HUD / tabs / levelinfoTab / rankOk.value = saveData.rank3
		if "rank4" in saveData:
			$HUD / tabs / levelinfoTab / rankErm.value = saveData.rank4
		if "levelBounds" in saveData:
			$HUD / tabs / levelinfoTab / levelBounds.value = saveData.levelBounds
		if "light" in saveData:
			$HUD / tabs / levelinfoTab / modulate.color = colorify(saveData.light)
		if "par" in saveData:
			$HUD / tabs / levelinfoTab / par.value = saveData.par
		if "time" in saveData:
			$HUD / tabs / levelinfoTab / time.value = saveData.time
		if "song" in saveData:
			$HUD / tabs / levelinfoTab / song.selected = saveData.song
		if "customSongName" in saveData:
			$HUD / tabs / customTab / songName.text = saveData.customSongName
		if "bg" in saveData:
			$editorFloor.texture = $HUD / tabs / levelinfoTab / bgSelect.get_item_icon(saveData.bg)
			bg = saveData.bg
		if "bpm" in saveData:
			$HUD / tabs / customTab / bpm.value = saveData.bpm
		if "loopPoint" in saveData:
			$HUD / tabs / customTab / loopoffset.value = saveData.loopPoint
		if "tiles" in saveData:
			for i in saveData.tiles:
				$tiles.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
		if "switchTiles1" in saveData:
			if saveData.switchTiles1.size() != 0:
				for i in saveData.switchTiles1:
					$switchtiles1.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
		if "switchTiles2" in saveData:
			if saveData.switchTiles2.size() != 0:
				for i in saveData.switchTiles2:
					$switchtiles2.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
		if "switchTiles3" in saveData:
			if saveData.switchTiles3.size() != 0:
				for i in saveData.switchTiles3:
					$switchtiles3.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
		if "switchTiles4" in saveData:
			if saveData.switchTiles4.size() != 0:
				for i in saveData.switchTiles4:
					$switchtiles4.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
		if "dogtiles" in saveData:
			if saveData.dogtiles.size() != 0:
				for i in saveData.dogtiles:
					$dogtiles.set_cell(vectorify(i[0]), 1, vectorify(i[1]))
		if "tBright" in saveData:
			$HUD / tabs / tilesTab / bright.color = colorify(saveData.tBright)
		if "tNormal" in saveData:
			$HUD / tabs / tilesTab / normal.color = colorify(saveData.tNormal)
		if "tDark" in saveData:
			$HUD / tabs / tilesTab / dark.color = colorify(saveData.tDark)
		if "tExtra" in saveData:
			$HUD / tabs / tilesTab / extra.color = colorify(saveData.tExtra)
		if "customtiles" in saveData:
			$HUD / tabs / customTab / tiles.text = saveData.customtiles
		if "switch1customtiles" in saveData:
			$HUD / tabs / customTab / tiles2.text = saveData.switch1customtiles
		if "switch2customtiles" in saveData:
			$HUD / tabs / customTab / tiles3.text = saveData.switch2customtiles
		if "switch3customtiles" in saveData:
			$HUD / tabs / customTab / tiles4.text = saveData.switch3customtiles
		if "switch4customtiles" in saveData:
			$HUD / tabs / customTab / tiles5.text = saveData.switch4customtiles
		if "dogcustomtiles" in saveData:
			$HUD / tabs / customTab / tiles6.text = saveData.dogcustomtiles
		if "mods" in saveData:
			$HUD / tabs / customTab / modifiers.text = saveData.mods
		reloadCustomTiles()
		reloadCustom()
		var obj: = 1
		if "deco" in saveData:
			for i in saveData.deco:
				var d = dec.instantiate()
				add_child(d, true)
				obj += 1
				d.position = fvectorify(i[0])
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
				d.add_to_group("editorObject")
		if "nodes" in saveData:
			for i in saveData.nodes:
				var d = load(i[4]).instantiate()
				d.add_to_group("editorObject")
				var block = false
				if d is Block && d.get_child(1) is NinePatchRect && d is not KeyDoor:
					block = true
				if d is Ghost:
					d.z_index = 10
				if i[5] != "sand":
					var tempVars = []
					var tempVa = []
					for l in d.get_script().get_script_property_list():
						tempVars.append(l)
						tempVa.append(d.get(l.get("name")))
						d.script = load("res://assetsNEW/scenes/game/menus/leveleditor/editorNoScript.gd")
					d.variables = i[3]
				add_child(d, true)
				if block:
					d.get_child(1).texture = load("res://assetsNEW/graphics/gimmicks/dblockMonochrome.png")
				d.position = fvectorify(i[0])
				d.scale = fvectorify(i[1])
				d.modulate = colorify(i[2])
				var pp = 0
				for p in objectScenes:
					if load(p.object) == load(i[4]):
						d.add_to_group(str(pp))
					pp += 1
				if i[5] != "sand":
					for j in i[3].keys():
						if i[3].get(j) != null:
							d.set(j, i[3].get(j))
				else:
					var res = []
					for a in i[3].rsplit("("):
						res.append(fvectorify(a))
					res.remove_at(0)
					d.set_polygon(res)
					if i[5] != "sand":
						d.variables.deco = int(i[6])


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


func _on_load_pressed() -> void :
	saving = false
	$FileDialog.file_mode = 0
	$FileDialog.visible = true

func playtestLevel():
	fullui.test_mode = true
	process_mode = Node.PROCESS_MODE_DISABLED
	position = Vector2(99999, 99999)
	visible = false
	$HUD.visible = false
	var lvl = load("res://assetsNEW/scenes/game/menus/leveleditor/editorLevel.tscn").instantiate()
	lvl.levelPath = levelPath
	var master = get_parent().get_parent()
	master.customPath = levelPath.get_base_dir()
	lvl.test = true
	lvl.editor = self
	camera.enabled = false
	get_tree().current_scene.add_child(lvl)

func _on_playtest_pressed() -> void :
	var master = get_parent().get_parent()
	master.oldCustomSong = "afsajfisjfiosj"
	saveto(levelPath)
	playtestLevel()


func _on_clear_pressed() -> void :
	clearPresses += 1
	clearTimer = 120
	$HUD / TopTab / clear.text = "CONFIRM " + str(clearPresses) + "/3"
	if clearPresses == 4:
		$pickOption.show()
		for i in tileLayers:
			i.clear()
		for i in get_tree().get_nodes_in_group("editorObject"):
			i.queue_free()
		$HUD / tabs / levelinfoTab / rankPeak.value = 7500
		$HUD / tabs / levelinfoTab / rankSwag.value = 6500
		$HUD / tabs / levelinfoTab / rankOk.value = 5500
		$HUD / tabs / levelinfoTab / rankErm.value = 5000
		$HUD / tabs / levelinfoTab / levelBounds.value = 256
		$HUD / tabs / levelinfoTab / par.value = 0
		$HUD / tabs / levelinfoTab / time.value = 0
		$HUD / tabs / levelinfoTab / song.select(0)
		$HUD / tabs / levelinfoTab / bgSelect.select(0)
		$HUD / tabs / levelinfoTab / modulate.color = Color.WHITE
		for i in $HUD / tabs / customTab.get_children():
			if i is LineEdit:
				i.text = ""
		clearPresses = 0
		$HUD / TopTab / clear.text = "CLEAR"


func _on_reload_pressed() -> void :
	reloadCustom()


func _on_reload_custom_pressed() -> void :
	reloadCustomTiles()

func reloadCustom():
	var item_list = $HUD / tabs / decoTab / ItemList
	while item_list.item_count > vanillaDeco:
		item_list.remove_item(item_list.item_count - 1)
	var path = levelPath.get_base_dir()
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name == "":
				break
			elif file_name.ends_with(".png") || file_name.ends_with(".jpg"):
				var image = Image.new()
				image.load(path + "/" + file_name)
				var t = ImageTexture.create_from_image(image)
				$HUD / tabs / decoTab / ItemList.add_item(file_name, t)
		dir.list_dir_end()


func reloadCustomTiles():
	$HUD / tabs / tilesTab / tilesPicker.tile_set = $HUD / tabs / tilesTab / tilesPicker.tile_set.duplicate()
	$tiles.tile_set = $tiles.tile_set.duplicate()
	$switchtiles1.tile_set = $switchtiles1.tile_set.duplicate()
	$switchtiles2.tile_set = $switchtiles2.tile_set.duplicate()
	$switchtiles3.tile_set = $switchtiles3.tile_set.duplicate()
	$switchtiles4.tile_set = $switchtiles4.tile_set.duplicate()
	$dogtiles.tile_set = $dogtiles.tile_set.duplicate()
	var path = levelPath.get_base_dir()
	var t = load_image(path + "/" + $HUD / tabs / customTab / tiles.text)
	if t != null:
		$HUD / tabs / tilesTab / tilesPicker.tile_set.get_source(1).texture = t
		$tiles.tile_set.get_source(1).texture = t
	t = load_image(path + "/" + $HUD / tabs / customTab / tiles2.text)
	if t != null:
		$switchtiles1.tile_set.get_source(1).texture = t
	t = load_image(path + "/" + $HUD / tabs / customTab / tiles3.text)
	if t != null:
		$switchtiles2.tile_set.get_source(1).texture = t
	t = load_image(path + "/" + $HUD / tabs / customTab / tiles4.text)
	if t != null:
		$switchtiles3.tile_set.get_source(1).texture = t
	t = load_image(path + "/" + $HUD / tabs / customTab / tiles5.text)
	if t != null:
		$switchtiles4.tile_set.get_source(1).texture = t
	t = load_image(path + "/" + $HUD / tabs / customTab / tiles6.text)
	if t != null:
		$dogtiles.tile_set.get_source(1).texture = t

func load_image(path: String):	
	var image = Image.load_from_file(path)
	var texture = ImageTexture.create_from_image(image)
	return texture


func _on_create_pressed() -> void :
	saving = true
	$FileDialog.file_mode = 4
	$FileDialog.set_current_dir(get_appdata_path())
	$FileDialog.visible = true

func _on_edit_pressed() -> void :
	saving = false
	$FileDialog.file_mode = 0
	$FileDialog.set_current_dir(get_appdata_path())
	$FileDialog.visible = true

func get_appdata_path() -> String:
	return OS.get_user_data_dir().path_join("custom_levels")

func _on_music_toggle_pressed() -> void :
	music.playing = !music.playing

@onready var tools: Control = $HUD / Tools

func _on_tools_pressed() -> void :
	tools.visible = !tools.visible


func _on_placement_mode_pressed() -> void :
	selectMode = false


func _on_select_mode_pressed() -> void :
	selectMode = true

func popup(text: String):
	var p: = newPopup.instantiate()
	p.object = p
	add_child(p)
	p.scale /= 1.5
	p.position = get_global_mouse_position()
	p.scoreText.text = text
	p.preserve_obj = true
	p.popup()


var s = 0
func _on_switch_toggle_pressed() -> void :
	s += 1
	if s > 4:
		s = 0
	if s == 0:
		$switchtiles1.material.set("shader_parameter/alpha", 1.0)
		$switchtiles2.material.set("shader_parameter/alpha", 1.0)
		$switchtiles3.material.set("shader_parameter/alpha", 1.0)
		$switchtiles4.material.set("shader_parameter/alpha", 1.0)
	if s == 1:
		$switchtiles1.material.set("shader_parameter/alpha", 1.0)
		$switchtiles2.material.set("shader_parameter/alpha", 0.2)
		$switchtiles3.material.set("shader_parameter/alpha", 0.2)
		$switchtiles4.material.set("shader_parameter/alpha", 0.2)
	if s == 2:
		$switchtiles1.material.set("shader_parameter/alpha", 0.2)
		$switchtiles2.material.set("shader_parameter/alpha", 1.0)
		$switchtiles3.material.set("shader_parameter/alpha", 0.2)
		$switchtiles4.material.set("shader_parameter/alpha", 0.2)
	if s == 3:
		$switchtiles1.material.set("shader_parameter/alpha", 0.2)
		$switchtiles2.material.set("shader_parameter/alpha", 0.2)
		$switchtiles3.material.set("shader_parameter/alpha", 1.0)
		$switchtiles4.material.set("shader_parameter/alpha", 0.2)
	if s == 4:
		$switchtiles1.material.set("shader_parameter/alpha", 0.2)
		$switchtiles2.material.set("shader_parameter/alpha", 0.2)
		$switchtiles3.material.set("shader_parameter/alpha", 0.2)
		$switchtiles4.material.set("shader_parameter/alpha", 1.0)
