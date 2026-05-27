extends Node2D

@onready var player: CharacterBody2D = $Player

# Preload interface layout assets directly from the filesystem
var dialogue_scene = preload("res://Scenes/DialogueBox.tscn")
var letter_wheel_scene = preload("res://Scenes/NewLetterWheel.tscn")

var active_dialogue_instance: CanvasLayer = null
var active_puzzle_instance: CanvasLayer = null

func _ready() -> void:
	# Listen to entry triggers from our event global pipeline
	GameManager.open_dialogue.connect(_on_dialogue_requested)
	GameManager.play_puzzle.connect(_on_start_puzzle)

func _on_dialogue_requested(text: String, words: Array[String], bg: Texture2D) -> void:
	player.set_physics_process(false)
	
	# Instantiate and display the dialogue choice window
	active_dialogue_instance = dialogue_scene.instantiate()
	add_child(active_dialogue_instance)
	
	# Force the dialogue box canvas layer sorting priority above the mini-game wheel canvas!
	active_dialogue_instance.layer = 2 
	
	# Pass the tracked speaker ID to display the name over the box
	var speaker_name = GameManager.current_talking_npc
	active_dialogue_instance.start_dialogue(speaker_name, text)
	
	# Listen for the player's choice response
	active_dialogue_instance.choice_selected.connect(func(accepted: bool):
		if accepted:
			# Player pressed YES! Keep the dialogue box alive, just launch the puzzle wheel
			_on_start_puzzle(words, bg)
		else:
			# Player pressed NO! Clean up everything and return to walking around
			return_to_overworld()
	)

func _on_start_puzzle(_words: Array[String], background_texture: Texture2D) -> void:
	player.set_physics_process(false)
	
	# Instantiate and setup your letter wheel canvas layer
	active_puzzle_instance = letter_wheel_scene.instantiate()
	
	if "current_character_id" in active_puzzle_instance:
		active_puzzle_instance.current_character_id = GameManager.current_talking_npc
		
	add_child(active_puzzle_instance)
	
	# Safe strict-type initialization pass
	var empty_string_array: Array[String] = []
	active_puzzle_instance.initialize_game(empty_string_array, background_texture, 3, 2)

func return_to_overworld() -> void:
	if active_dialogue_instance:
		active_dialogue_instance.queue_free()
	if active_puzzle_instance:
		active_puzzle_instance.queue_free()
		
	active_dialogue_instance = null
	active_puzzle_instance = null
	
	GameManager.is_dialogue_active = false
	player.set_physics_process(true)
	
