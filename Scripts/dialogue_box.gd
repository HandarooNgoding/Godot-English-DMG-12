extends CanvasLayer

signal choice_selected(accepted: bool)

# --- Node References ---
@onready var dialogue_label: RichTextLabel = $UIAnchorWrapper/Panel/DialogueLabel
@onready var choice_container: HBoxContainer = $UIAnchorWrapper/Panel/ChoiceContainer
@onready var yes_button: Button = $UIAnchorWrapper/Panel/ChoiceContainer/YesButton
@onready var no_button: Button = $UIAnchorWrapper/Panel/ChoiceContainer/NoButton
@onready var text_timer: Timer = $TextTimer

# References to custom Name tag nodes
@onready var name_box: PanelContainer = $UIAnchorWrapper/NameBox
@onready var name_label: Label = $UIAnchorWrapper/NameBox/NameLabel

# --- Speed Setup ---
@export var normal_type_speed: float = 0.04
var is_typing: bool = false

# --- Exact Skip State Tracking ---
var is_fast_forwarding: bool = false
var skip_elapsed_time: float = 0.0
var skip_duration: float = 0.5 
var characters_at_skip_start: float = 0.0
var total_character_count: float = 0.0

# State tracker to see if we're asking a question or playing a mini-game
var puzzle_mode_active: bool = false

func _ready() -> void:
	choice_container.visible = false
	dialogue_label.text = ""
	if name_box: name_box.hide()
	
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	text_timer.timeout.connect(_on_timer_timeout)

func start_dialogue(npc_name: String, text_to_display: String) -> void:
	show()
	set_process(true)
	puzzle_mode_active = false
	
	if name_box and name_label:
		if npc_name != "":
			name_box.show()
			name_label.text = npc_name
		else:
			name_box.hide()
			
	dialogue_label.text = text_to_display
	dialogue_label.visible_characters = 0 
	choice_container.visible = false
	is_typing = true
	is_fast_forwarding = false
	
	text_timer.wait_time = normal_type_speed
	text_timer.start()

func show_puzzle_hint(hint_text: String) -> void:
	puzzle_mode_active = true
	choice_container.visible = false
	
	dialogue_label.text = hint_text
	dialogue_label.visible_characters = -1 
	
	if text_timer and not text_timer.is_stopped():
		text_timer.stop()
		
	is_typing = false
	is_fast_forwarding = false

func _on_timer_timeout() -> void:
	if dialogue_label.visible_characters < dialogue_label.get_total_character_count():
		dialogue_label.visible_characters += 1
	else:
		finish_typing()

func _process(delta: float) -> void:
	if is_fast_forwarding:
		skip_elapsed_time += delta
		var t = clamp(skip_elapsed_time / skip_duration, 0.0, 1.0)
		var current_chars = lerp(characters_at_skip_start, total_character_count, t)
		dialogue_label.visible_characters = int(current_chars)
		
		if t >= 1.0:
			finish_typing()

func _input(event: InputEvent) -> void:
	if puzzle_mode_active: 
		return
		
	# FIXED: Added explicit checking for input event types before evaluating mouse buttons
	if event.is_action_pressed("interact"):
		if is_typing and not is_fast_forwarding:
			if dialogue_label.visible_characters < dialogue_label.get_total_character_count() - 2:
				activate_true_skip()
	elif event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			if is_typing and not is_fast_forwarding:
				if dialogue_label.visible_characters < dialogue_label.get_total_character_count() - 2:
					activate_true_skip()

func activate_true_skip() -> void:
	text_timer.stop()
	characters_at_skip_start = float(dialogue_label.visible_characters)
	total_character_count = float(dialogue_label.get_total_character_count())
	skip_elapsed_time = 0.0
	is_fast_forwarding = true

func finish_typing() -> void:
	text_timer.stop()
	is_typing = false
	is_fast_forwarding = false
	dialogue_label.visible_characters = -1 
	if not puzzle_mode_active:
		show_choices()

func show_choices() -> void:
	choice_container.visible = true
	yes_button.grab_focus()

func _on_yes_pressed() -> void:
	choice_selected.emit(true)

func _on_no_pressed() -> void:
	choice_selected.emit(false)
	close_dialogue()

func close_dialogue() -> void:
	set_process(false)
	hide()
	queue_free()
