# This is where I patch most of the editor :P
class_name BMEditorPatcher
extends Node

@onready var editorFont = preload("res://assetsNEW/fonts/windows_command_prompt.ttf")
const EDITOR_PATH := "/root/Master/FullEditorUi/levelEditor"
var editor: levelEditor
var bm = BingusMod.new()
var openRecentButton: Button = null
var openRecentOptionButton: OptionButton = null
var hideSidebarArrow: Button = null
var levelScriptPath: LineEdit = null
var sidebarIsOffset: bool = false

## it stands for editor node
func en(node: String = "") -> Node:
	if node == "": return get_node(EDITOR_PATH)
	return get_node(EDITOR_PATH.path_join(node))

# setup UI
func bm_editor_on_load():
	bm.recentLevels = bm.load_recent_levels()
	if bm.conf.open_recent_button:
		if openRecentButton == null:
			openRecentButton = bm.UI.openRecentButton.call()
			openRecentButton.pressed.connect(_on_open_recent_pressed)
			en(&"pickOption").add_child(openRecentButton)
			BingusMod.message("added open recent button woohoo !")

		if openRecentOptionButton == null:
			var recents = bm.load_recent_levels()
			openRecentOptionButton = bm.UI.openRecentOptionButton.call()

			# Loop through the most recent levels and add them to the OptionButton
			for i in int(bm.conf.num_recent_levels):
				if recents.size() > i:
					openRecentOptionButton.add_item(recents[i].get_file())
					# The tooltip of each item is its absolute path.
					openRecentOptionButton.set_item_tooltip(openRecentOptionButton.item_count-1, recents[i])
				else: break
			
			en(&"pickOption").add_child(openRecentOptionButton)
			BingusMod.message("added open recent button ay a !")
		
	if hideSidebarArrow == null && bm.conf.hide_sidebar_arrow:
		hideSidebarArrow = bm.UI.hideSidebarArrow.call()
		hideSidebarArrow.pressed.connect(_on_hide_sidebar_pressed)
		
		en(&"HUD").add_child(hideSidebarArrow)
		BingusMod.message("added sidebar arrow wo w  !")
	
	if bm.conf.level_scripts:
		# Make the modifiers input slightly smaller to allow us to add our input
		var modifiersInput = en(&"HUD/tabs/customTab/modifiers")
		modifiersInput.size.y = 22.0
		modifiersInput.position.y += 20
		
		levelScriptPath = bm.UI.levelScriptPath.call()
		levelScriptPath.visibility_changed.connect(func():
			if levelScriptPath.visible == false || levelScriptPath.text != "":
				return

			var json_data = JSON.parse_string(
				FileAccess.open(editor.levelPath, FileAccess.READ).get_as_text()
			)
			if "levelScript" in json_data:
				levelScriptPath.text = json_data.levelScript
)
		
		en(&"HUD/tabs/customTab").add_child(levelScriptPath)
		# for some reason i have to do this to set its size ?? idfk
		en(&"HUD/tabs/customTab/levelScript").size = Vector2i(224, 22)
	
	# ALWAYS DO THIS LAST!
	if bm.conf.help_tooltips:
		bm_add_tooltips("HUD/", bm.TOOLTIPS)

func bm_add_tooltips(base, dict) -> void:
	for key in dict:
		var val = dict[key]
		var node_path = base + key
		if val is Dictionary:
			bm_add_tooltips(node_path + "/", val)
			continue
		var node = en(node_path)
		if node == null: continue
		node.set_tooltip_text(val)

		if node_path == "HUD/tabs/decoTab/reload" \
		|| node_path == "HUD/tabs/customTab/reload":
			# Objects not using the editor theme don't have their font set to the editor's one.
			var theme: Theme = node.get_theme().duplicate()
			theme.set_font(&"font", &"TooltipLabel", editorFont)
			node.set_theme(theme)

func bm_save(path: String):
	# TODO: FIX
	bm.add_recent_level(path)
	if editor.saving:
		pass
	else:
		var json_string = FileAccess.open(path, FileAccess.READ).get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			push_error("JSON parse error ", json.get_error_message(), " on line ", json.get_error_line())
			return
		var saveData = json.get_data()
		if bm.conf.level_scripts == true && "levelScript" in saveData:
			en(&"HUD/tabs/customTab/levelScript").text = saveData.levelScript

func _on_open_recent_pressed() -> void:
	var optionButton = openRecentOptionButton
	var path = optionButton.get_item_tooltip(optionButton.selected)
	editor.saving = false
	editor.save(path)
	bm.add_recent_level(path)

func _on_hide_sidebar_pressed() -> void:
	if sidebarIsOffset:
		en(&"HUD").offset.x = 0
		hideSidebarArrow.text = " < "
	else:
		en(&"HUD").offset.x = -BingusMod.SIDEBAR_WIDTH
		hideSidebarArrow.text = " > "
	editor.get_parent().get_parent().get_child(1).offset.x = en(&"HUD").offset.x
	sidebarIsOffset = !sidebarIsOffset

func load_ui_patch():
	if en(&"pickOption").visible:
		bm_editor_on_load()

func _ready():
	editor = en()

	en(&"HUD/TopTab/clear").pressed.connect(load_ui_patch)
	editor.ready.connect(load_ui_patch)
	en(&"FileDialog").file_selected.connect(bm_save)
