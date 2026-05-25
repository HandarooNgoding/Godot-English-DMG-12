extends Node

signal open_dialogue(text: String, words: Array[String], bg: Texture2D)
signal play_puzzle(words: Array[String], background_texture: Texture2D)

# --- NEW: Master State Lock Variable ---
var is_dialogue_active: bool = false

func trigger_npc_dialogue(text: String, words: Array[String], bg: Texture2D) -> void:
	# Set the flag to true the moment a conversation begins
	is_dialogue_active = true
	open_dialogue.emit(text, words, bg)

func start_minigame(words: Array[String], background_texture: Texture2D) -> void:
	play_puzzle.emit(words, background_texture)
