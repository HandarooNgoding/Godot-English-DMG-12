extends Node2D

@onready var sprite_2d: AnimatedSprite2D = $Sprite2D
@onready var interact_prompt: Sprite2D = $InteractPrompt 

# --- Quest Configurations ---
@export_enum("Mom", "Dad", "Sibling", "Grandma") var npc_name: String = "Mom"
@export var quest_words: Array[String] = ["CAT", "BAT", "RAT"]

# --- Visuals & Expressions ---
@export var npc_animations: SpriteFrames
@export var quest_background_image: Texture2D
@export_multiline var dialogue_text: String = "Hello there! Would you like to play a word game with me?"

var player_in_range: bool = false
var fade_tween: Tween

func _ready() -> void:
	interact_prompt.modulate.a = 0.0
	
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)
	
	# NEW: Listen globally for updates so if the player clears this NPC's puzzle,
	# the "E" button vanishes instantly without having to walk away first!
	QuestManager.quest_updated.connect(_on_quest_system_updated)
	
	# Apply the unique animation resource dynamically and play it
	if sprite_2d and npc_animations:
		sprite_2d.sprite_frames = npc_animations
		sprite_2d.play("default")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		# FIXED: Only display the prompt if the quest hasn't been completed yet!
		if not QuestManager.is_quest_completed(npc_name):
			fade_prompt(1.0) 

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		fade_prompt(0.0) 

func _input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact") and not GameManager.is_dialogue_active:
		# Block trigger if the minigame is already completed
		if QuestManager.is_quest_completed(npc_name):
			print(npc_name, " has nothing else for you to do.")
			return
			
		fade_prompt(0.0) 
		start_npc_interaction()

func start_npc_interaction() -> void:
	# CRITICAL: Tell the GameManager exactly who this NPC is!
	GameManager.current_talking_npc = npc_name
	GameManager.trigger_npc_dialogue(npc_name, dialogue_text, quest_words, quest_background_image)

# NEW FUNCTIONS: Handles real-time cleanup when returning from minigames
func _on_quest_system_updated() -> void:
	# If the player is standing right next to this NPC and just completed their quest,
	# instantly dissolve the visual prompt!
	if QuestManager.is_quest_completed(npc_name):
		fade_prompt(0.0)

func fade_prompt(target_alpha: float) -> void:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
		
	fade_tween = create_tween()
	fade_tween.tween_property(interact_prompt, "modulate:a", target_alpha, 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
