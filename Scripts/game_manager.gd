extends Node

signal open_dialogue(text: String, words: Array[String], bg: Texture2D)
signal play_puzzle(words: Array[String], background_texture: Texture2D)

# Master State Lock Variable
var current_talking_npc: String = ""
var is_dialogue_active: bool = false

func trigger_npc_dialogue(npc_name: String, text: String, words: Array[String], bg: Texture2D) -> void:
	is_dialogue_active = true
	current_talking_npc = npc_name
	open_dialogue.emit(text, words, bg)

func start_minigame(words: Array[String], background_texture: Texture2D) -> void:
	# Cleaned up: Let main_hub assign it cleanly during initialization instantiation!
	play_puzzle.emit(words, background_texture)
