extends CanvasLayer

@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton
@onready var win_label: Label = $CenterContainer/VBoxContainer/WinLabel

func _ready() -> void:
	# Make the button immediately focusable for controller/keyboard users
	restart_button.grab_focus()
	
	# Connect the press event
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed() -> void:
	# Reset any global variables in your GameManager that might lock up your player
	GameManager.is_dialogue_active = false
	
	# If your QuestManager stores quest completion, clear it out here!
	# Example: QuestManager.reset_all_quests()
	
	# Reload your main gameplay loop map/hub scene
	# Replace this path with the exact directory location of your main hub scene file
	var error = get_tree().change_scene_to_file("res://Scenes/MainHub.tscn")
	if error != OK:
		print("Error: Could not reload the main hub scene. Check your file path string!")
