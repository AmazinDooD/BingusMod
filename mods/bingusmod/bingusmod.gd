@icon("res://assetsNEW/graphics/editor/erm.png")
class_name BingusMod extends Node

const _a = &"hi! this is my first mod so if im doing something horribly wrong please tell me :3"
const _b = &"(i probably am lmao,,) anyways, enjoy my code :P (or don't)"

var conf
@onready var recentLevels: Array = load_recent_levels()
@onready var newPopup = preload("res://assetsNEW/scenes/objects/misc/score_popup.tscn")

const MOD_ID = "amazindood.bingusmod"
const RECENT_FILES_PATH = "user://mod_data/"+MOD_ID+".recentLevels.json"
const CONFIG_PATH = "user://mod_data/configs/"+MOD_ID+".json"
const RECENT_BUTTON_POS: Vector2i = Vector2i(343, 328)
const RECENT_OPTION_BUTTON_POS: Vector2i = RECENT_BUTTON_POS + Vector2i(200, 1)
const SIDEBAR_WIDTH = 256
const HIDE_SIDEBAR_OFFSET = 10
const HIDE_SIDEBAR_POS: Vector2i = Vector2i(SIDEBAR_WIDTH + HIDE_SIDEBAR_OFFSET, HIDE_SIDEBAR_OFFSET)
const HOVER_LIGHTEN_AMT = 0.2
const CLICK_LIGHTEN_AMT = 0.35
const TOOLTIPS: = { # Relative to levelEditor/HUD/
	"tabs": {
		"levelinfoTab": {
			"levelName": 	"The name of the level.",
			"levelAuthor":	"The author(s) of the level.",
			"world": 		"The name of the world this level belongs to. (e.g. 4-2)",
			"id":			"The ID of the level in the world, usually a number. (e.g. 4-2)",
			"rankPeak":		"The amount of points required to get the Peak rank.",
			"rankSwag":		"The amount of points required to get the Nice rank.",
			"rankOk":		"The amount of points required to get the OK rank.",
			"rankErm":		"The amount of points required to get the Below Average rank.\nAny amount of points lower than this will give you the Atrocious rank.",
			"levelBounds": 	"The width and height of the level, going outside of these will be an O.B.",
			"par":			"The par of the level. This should be the amount of strokes it would\ntake a relatively skilled player to complete the level.",
			"time":			"The time taken to complete the level. This should be the amount of\ntime it would take a relatively skilled player to complete the level.",
			"song":			"The song that plays in the background of the level. If set to Custom,\nyou should specify a file name in the Custom tab.",
			"bgSelect":		"The background used for the level.",
			"Label4":		"The background used for the level.",
			"modulate":		"The colour of the background lighting used for the level."
		},
		"tilesTab": {
			"layer": 		"The type of tile that will be placed.",
			"bright": 		"The \"bright\" colour of the tiles, used for recolouring them.",
			"normal": 		"The \"normal\" colour of the tiles, used for recolouring them.",
			"dark": 		"The \"dark\" colour of the tiles, used for recolouring them.",
			"extra": 		"The \"extra\" colour of the tiles, used for recolouring them.",
		},
		"objectsTab": {
			"ItemList": 	"The object that will be placed."
		},
		"decoTab": {
			"ItemList": 	"The type of decoration that will be placed.",
			"reload": 		"Adds any new images in this world's folder to the list of decoration images.",
			"vFrames":		"For animated images, the number of rows of frames.",
			"hFrames":		"For animated images, the number of columns of frames.",
			"Z Index":		"The decoration's Z index. Decoration with higher Z indices\nwill be layered above decoration with lower ones.",
			"speed":		"For animated images, how quickly it cycles through its frames.",
			"frame":		"For animated images, the starting frame of the image.",
			"collision":	"Whether the player will collide with the decoration or not."
		},
		# hotkeysTab has literally nothing lmao
		"customTab": {
			"songName": 	"When the Song option is set to Custom, this option is the name of\nthe custom song, including its file extension.",
			"tiles": 		"Specifies a filepath to a tile set to use for normal tiles.",
			"tiles2": 		"Specifies a filepath to a tile set to use for the first set of switching blocks.",
			"tiles3": 		"Specifies a filepath to a tile set to use for the second set of switching blocks.",
			"tiles4": 		"Specifies a filepath to a tile set to use for the third set of switching blocks.",
			"tiles5": 		"Specifies a filepath to a tile set to use for the fourth set of switching blocks.",
			"tiles6": 		"Specifies a filepath to a tile set to use for dog tiles.",
			"modifiers":	"A list of playthrough modifies to use for this level.\nEntries should be separated by commas.",
			"bpm":			"When the Song option is set to Custom, specifies the BPM of your custom song.\nThe icon in the pause menu dances at this tempo.",
			"reload":		"Reloads each tile set using each filepath that is set above.",
			"levelScript": 	"The path to this level's custom script."
		}
	},
	"TopTab": {
		"save": 	"Saves the level to a file.",
		"load": 	"Loads a level from a file.",
		"playtest": "Starts a playtest of the level.",
		"clear":	"Clears the level (but doesn't save it).",
		"tools":	"Opens a menu with some tools.",
	},
	"Tools": {
		"PlacementMode":	"Switches to placement mode.",
		"SelectMode":		"Switches to selection mode.",
		"MusicToggle":		"Turns on/off background music in the editor.",
		"switchToggle":		"Switches between showing all switching block tiles and only showing set 1/2/3/4.",
	},
	"tabselector": "Switches between tabs of the editor.",
	"hideSidebar": "Hides the panel on the left side of the editor.",
}

static func message(message: String):
	print("[BingusMod] ", message)

## Loads a .json file from a path and parses it.
static func load_json(path) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

static func load_config() -> Variant:
	# guess we reading configs now
	return load_json(CONFIG_PATH)

func save_recent_levels(conf = null) -> void:
	var levelsToSave: Array[String] = []
	for i in int(conf.num_recent_levels):
		if recentLevels.size() > i:
			levelsToSave.append(recentLevels[i - 1])
		else: break

	var text = JSON.stringify(levelsToSave)
	var file = FileAccess.open(RECENT_FILES_PATH, FileAccess.WRITE)
	file.store_string(text)
	message("saved recent levels")

func load_recent_levels() -> Array:
	if !FileAccess.file_exists(RECENT_FILES_PATH):
		message("recent files json doesnt exist, creating it :P")
		FileAccess.open(RECENT_FILES_PATH, FileAccess.WRITE).store_string("[]")
		return []
	
	message("loading recent files json")
	return load_json(RECENT_FILES_PATH)

func add_recent_level(path: String, conf = null) -> void:
	if recentLevels.has(path):
		recentLevels.erase(path)

	recentLevels.push_back(path)

	if recentLevels.size() > int(conf.num_recent_levels):
		for i in recentLevels.size() - int(conf.num_recent_levels):
			recentLevels.remove_at(-1)
	
	message("new level opened!")
	save_recent_levels(conf)

static func pan_key_down(conf = null) -> bool:
	if conf.ctrl_to_pan:
		return Input.is_action_pressed("shift") || Input.is_action_pressed("ctrl")
	else:
		return Input.is_action_pressed("shift")

func _init() -> void:
	conf = load_config()

func _ready() -> void:
	message("guess what ,,,    the mod just loaded !! woa! !")

func _on_coolermods_config_saved(mod: ModLoader.Mod, data: Dictionary):
	if mod.id == MOD_ID:
		conf = data
