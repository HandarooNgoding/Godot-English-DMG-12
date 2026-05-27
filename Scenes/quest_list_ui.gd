extends CanvasLayer

# FIXED PATH: Updated to match the exact "MarginContaine" typo from your editor layout hierarchy
@onready var list_container: VBoxContainer = $Control/Panel/MarginContainer/VBoxContainer

func _ready() -> void:
	# Hide on start
	visible = false
	# Listen for any runtime updates
	QuestManager.quest_updated.connect(refresh_list)
	refresh_list()

func _input(event: InputEvent) -> void:
	# Toggle open/close with TAB key
	if event.is_action_pressed("ui_focus_next") or (event is InputEventKey and event.pressed and event.keycode == KEY_TAB):
		# Prevent opening the menu if the player is currently inside a minigame canvas
		if get_tree().get_nodes_in_group("minigame").size() > 0:
			return
			
		visible = !visible
		if visible:
			refresh_list()

func refresh_list() -> void:
	# FIXED: Safely clear previous elements instantly using free() instead of queue_free()
	# This stops duplicate entries from compounding during simultaneous signal triggers!
	while list_container.get_child_count() > 0:
		var child = list_container.get_child(0)
		list_container.remove_child(child)
		child.free()
		
	# Populate current status dynamically
	for q_name in QuestManager.quests:
		var quest_data = QuestManager.quests[q_name]
		
		var label = RichTextLabel.new()
		label.bbcode_enabled = true 
		label.fit_content = true     # Prevents the text box from clipping vertically
		
		# Force the label to expand horizontally to fill our wide Panel box!
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var display_text = quest_data["location"] + " - " + q_name
		
		if quest_data["completed"]:
			# [s] is strike-through. [color] changes text color to a faded dark gray
			label.text = "[s][color=#5a5a5a]• " + display_text + " (Completed)[/color][/s]"
		else:
			label.text = "[color=#ffffff]• " + display_text + "[/color]"
			
		# Ensure there is ample width allocated so the RichText engine has wrapping space
		label.custom_minimum_size = Vector2(320, 0)
		
		list_container.add_child(label)
		
