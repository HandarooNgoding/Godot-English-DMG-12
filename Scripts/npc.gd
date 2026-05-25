extends Node2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var interact_prompt: Sprite2D = $InteractPrompt # Reference to your new pixel E node

# --- Quest Configurations ---
@export var npc_name: String = "Quest Giver"
@export var quest_words: Array[String] = ["CAT", "BAT", "RAT"]

# --- Visuals & Expressions ---
@export var npc_overworld_sprite: Texture2D
@export var quest_background_image: Texture2D
@export_multiline var dialogue_text: String = "Hello there! Would you like to play a word game with me?"

var player_in_range: bool = false
var fade_tween: Tween

func _ready() -> void:
	# Force prompt to be completely transparent on startup
	interact_prompt.modulate.a = 0.0
	
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)
	
	if npc_overworld_sprite and sprite_2d:
		sprite_2d.texture = npc_overworld_sprite

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		fade_prompt(1.0) # Fade in smoothly to full opacity

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		fade_prompt(0.0) # Fade out smoothly to complete invisibility

func _input(event: InputEvent) -> void:
	# Ignore interactions completely if dialogue state layer is already busy
	if player_in_range and event.is_action_pressed("interact") and not GameManager.is_dialogue_active:
		fade_prompt(0.0) # Instantly hide prompt while talking
		start_npc_interaction()

func start_npc_interaction() -> void:
	GameManager.trigger_npc_dialogue(dialogue_text, quest_words, quest_background_image)

# --- NEW: Smooth Tween Fade Processing ---
func fade_prompt(target_alpha: float) -> void:
	# Kill any running fade animation so it doesn't fight with the new transition
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
		
	# Create a fresh frame-independent interpolation worker
	fade_tween = create_tween()
	
	# Transition the alpha channel ('modulate:a') over 0.25 seconds using a smooth curve
	fade_tween.tween_property(interact_prompt, "modulate:a", target_alpha, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
