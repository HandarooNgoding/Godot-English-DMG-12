extends Node2D

@onready var player: CharacterBody2D = $Player

# Preload our interface layout assets directly from the filesystem
var dialogue_scene = preload("res://Scenes/DialogueBox.tscn")
var letter_wheel_scene = preload("res://Scenes/LetterWheel.tscn")

var active_dialogue_instance: CanvasLayer = null
var active_puzzle_instance: CanvasLayer = null

func _ready() -> void:
	# Listen to entry triggers from our event global pipeline
	GameManager.open_dialogue.connect(_on_dialogue_requested)
	GameManager.play_puzzle.connect(_on_start_puzzle)

func _on_dialogue_requested(text: String, words: Array[String], bg: Texture2D) -> void:
	# 1. CRITICAL: Immediately lock down player physics movement inputs
	player.set_physics_process(false)
	
	# 2. Instantiate and mount our rolling dialogue node
	active_dialogue_instance = dialogue_scene.instantiate()
	add_child(active_dialogue_instance)
	
	# 3. Start drawing the left-to-right typewriter stream
	active_dialogue_instance.start_dialogue(text)
	
	# 4. Wait for the player's choice response
	active_dialogue_instance.choice_selected.connect(func(accepted: bool):
		if accepted:
			# If player selected "YES", spin up the minigame instance
			GameManager.start_minigame(words, bg)
		else:
			# If player selected "NO", close dialog and give back control
			return_to_overworld()
	)

func _on_start_puzzle(words: Array[String], background_texture: Texture2D) -> void:
	# Double check player remains locked while puzzle loads
	player.set_physics_process(false)
	
	active_puzzle_instance = letter_wheel_scene.instantiate()
	add_child(active_puzzle_instance)
	active_puzzle_instance.initialize_game(words, background_texture, 3, 3) 

func return_to_overworld() -> void:
	active_dialogue_instance = null
	active_puzzle_instance = null
	
	# CRITICAL: Release the global dialogue lock so characters can speak again!
	GameManager.is_dialogue_active = false
	
	player.set_physics_process(true)
	print("Movement unfrozen and dialogue lock cleared!")
