@icon("res://assetsNEW/graphics/editor/erm.png")
class_name BingusMod extends Node

const _a = &"hi! this is my first mod so if im doing something horribly wrong please tell me :3"
const _b = &"(i probably am lmao,,) anyways, enjoy my code :P (or don't)"
const _c = &"also, if you decompiled this through GDRE, why've you done that?"
const _d = &"the source code is on github: https://maglit.me/bingusmod-mainfile"

var conf: Dictionary
@onready var recentLevels: Array = load_recent_levels()
var editorTheme = load("res://assetsNEW/scenes/game/menus/leveleditor/editorTheme.tres")
var master: Master
var BMEditorPatcher = load("res://mods/bingusmod/editor_patcher.gd")

const MOD_ID := "amazindood.bingusmod"
const RECENT_FILES_PATH := "user://mod_data/"+MOD_ID+".recentLevels.json"
const CONFIG_PATH := "user://mod_data/configs/"+MOD_ID+".json"
const RECENT_BUTTON_POS := Vector2i(343, 328)
const RECENT_OPTION_BUTTON_POS := RECENT_BUTTON_POS + Vector2i(200, 1)
const SIDEBAR_WIDTH := 256
const HIDE_SIDEBAR_OFFSET := 10
const HIDE_SIDEBAR_POS := Vector2i(SIDEBAR_WIDTH + HIDE_SIDEBAR_OFFSET, HIDE_SIDEBAR_OFFSET)
const HOVER_LIGHTEN_AMT := 0.2
const CLICK_LIGHTEN_AMT := 0.35
var UI := {
	"openRecentButton": func():
		var b = Button.new()
		b.text = "Open recently edited level"
		b.position = RECENT_BUTTON_POS
		b.add_theme_font_size_override(&"font_size", 12)
		b.add_theme_constant_override(&"outline_size", 8)
		b.set_name(&"openRecent")
		return b,

	"openRecentOptionButton": func():
		var b = OptionButton.new()
		b.position = BingusMod.RECENT_OPTION_BUTTON_POS
		b.add_theme_font_size_override(&"font_size", 8)
		b.add_theme_constant_override(&"outline_size", 6)
		b.set_name(&"openRecentOptions")
		var popup = b.get_popup()
		popup.theme = editorTheme
		popup.add_theme_font_size_override(&"font_size", 10)
		
		b.add_item("--- Choose a level ---")
		b.set_item_disabled(0, true)
		b.select(0)
		return b,
	
	"hideSidebarArrow": func():
		var b = Button.new()
		b.theme = editorTheme
		b.position = BingusMod.HIDE_SIDEBAR_POS
		b.text = " < "
		b.set_name(&"hideSidebar")
		
		var styleboxNormal = StyleBoxFlat.new()
		styleboxNormal.set_bg_color(Color.BLACK)
		styleboxNormal.set_border_width_all(2)
		styleboxNormal.set_border_color(Color.DARK_GRAY.darkened(BingusMod.HOVER_LIGHTEN_AMT))
		b.add_theme_stylebox_override(&"normal", styleboxNormal)
		b.add_theme_stylebox_override(&"normal_mirrored", styleboxNormal)
		
		var styleboxHover = StyleBoxFlat.new()
		styleboxHover.set_bg_color(Color.BLACK.lightened(BingusMod.HOVER_LIGHTEN_AMT))
		styleboxHover.set_border_width_all(2)
		styleboxHover.set_border_color(Color.DARK_GRAY)
		b.add_theme_stylebox_override(&"hover", styleboxHover)
		b.add_theme_stylebox_override(&"hover_mirrored", styleboxHover)
		
		var styleboxClick = StyleBoxFlat.new()
		styleboxClick.set_bg_color(Color.BLACK.lightened(BingusMod.CLICK_LIGHTEN_AMT))
		styleboxClick.set_border_width_all(2)
		styleboxClick.set_border_color(Color.DARK_GRAY.lightened(BingusMod.CLICK_LIGHTEN_AMT - BingusMod.HOVER_LIGHTEN_AMT))
		b.add_theme_stylebox_override(&"pressed", styleboxClick)
		b.add_theme_stylebox_override(&"pressed_mirrored", styleboxClick)
		
		return b,

	"levelScriptPath": func() -> LineEdit:
		var l := LineEdit.new()
		l.set_placeholder("Level Script path")
		l.set_name(&"levelScript")
		l.set_theme(editorTheme)
		l.position = Vector2i(16, 304)
		return l
}
const TOOLTIPS := { # Relative to levelEditor/HUD/
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

func save_recent_levels() -> void:
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

func add_recent_level(path: String) -> void:
	if recentLevels.has(path):
		recentLevels.erase(path)

	recentLevels.push_back(path)

	if recentLevels.size() > int(conf.num_recent_levels):
		for i in recentLevels.size() - int(conf.num_recent_levels):
			recentLevels.remove_at(-1)
	
	message("new level opened!")
	save_recent_levels()

func pan_key_down() -> bool:
	if conf.ctrl_to_pan:
		return Input.is_action_pressed("shift") || Input.is_action_pressed("ctrl")
	else:
		return Input.is_action_pressed("shift")

# "inspiration" taken from coolermods
# please dont sue me justsomejello
func on_node_added_to_master(node: Node):
	if node is EditorUI:
		var editor = node.get_child(0)
		# NOW we do some shenangians
		editor.add_child(BMEditorPatcher.new())
		message("added BMEditorPatcher to level editor scene")

func _enter_tree():
	master = get_tree().current_scene as Master

func _init() -> void:
	conf = load_config()

func _ready() -> void:
	get_tree().current_scene.child_entered_tree.connect(on_node_added_to_master)
	
	message("guess what ,,,    the mod just loaded !! woa! !")

func _on_coolermods_config_saved(mod: ModLoader.Mod, data: Dictionary):
	if mod.id == MOD_ID:
		conf = data
