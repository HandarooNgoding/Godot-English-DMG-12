extends CanvasLayer

signal choice_selected(accepted: bool)

@onready var dialogue_label: RichTextLabel = $UIAnchorWrapper/Panel/DialogueLabel
@onready var choice_container: HBoxContainer = $UIAnchorWrapper/Panel/ChoiceContainer
@onready var yes_button: Button = $UIAnchorWrapper/Panel/ChoiceContainer/YesButton
@onready var no_button: Button = $UIAnchorWrapper/Panel/ChoiceContainer/NoButton
@onready var text_timer: Timer = $TextTimer

# --- Speed Setup ---
@export var normal_type_speed: float = 0.04
var is_typing: bool = false

# --- Exact Skip State Tracking ---
var is_fast_forwarding: bool = false
var skip_elapsed_time: float = 0.0
var skip_duration: float = 0.5 # Change this to 0.3 or 0.2 if you want it even faster!
var characters_at_skip_start: float = 0.0
var total_character_count: float = 0.0

func _ready() -> void:
	choice_container.visible = false
	dialogue_label.text = ""
	
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)
	text_timer.timeout.connect(_on_timer_timeout)

func start_dialogue(text_to_display: String) -> void:
	show()
	
	dialogue_label.text = text_to_display
	dialogue_label.visible_characters = 0 
	choice_container.visible = false
	is_typing = true
	is_fast_forwarding = false
	
	text_timer.wait_time = normal_type_speed
	text_timer.start()

func _on_timer_timeout() -> void:
	if dialogue_label.visible_characters < dialogue_label.get_total_character_count():
		dialogue_label.visible_characters += 1
	else:
		finish_typing()

func _process(delta: float) -> void:
	# This frame-independent loop takes over to guarantee the 0.5s limit
	if is_fast_forwarding:
		skip_elapsed_time += delta
		
		# Calculate the completion ratio (0.0 to 1.0) over exactly 0.5 seconds
		var t = clamp(skip_elapsed_time / skip_duration, 0.0, 1.0)
		
		# Linearly interpolate between where the text was when we skipped, and the end
		var current_chars = lerp(characters_at_skip_start, total_character_count, t)
		dialogue_label.visible_characters = int(current_chars)
		
		if t >= 1.0:
			finish_typing()

func _input(event: InputEvent) -> void:
	# Captures Spacebar, E, or Mouse clicks on the screen
	if (event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)):
		if is_typing and not is_fast_forwarding:
			# Safety check: No need to skip if there are fewer than 2 characters left
			if dialogue_label.visible_characters < dialogue_label.get_total_character_count() - 2:
				activate_true_skip()

func activate_true_skip() -> void:
	text_timer.stop() # Turn off the old stuttery timer loop entirely
	
	# Snapshot the exact state of the text right now
	characters_at_skip_start = float(dialogue_label.visible_characters)
	total_character_count = float(dialogue_label.get_total_character_count())
	skip_elapsed_time = 0.0
	
	is_fast_forwarding = true # Hand execution over to the frame-rate processor

func finish_typing() -> void:
	text_timer.stop()
	is_typing = false
	is_fast_forwarding = false
	dialogue_label.visible_characters = -1 # Ensure all remaining spaces are exposed
	show_choices()

func show_choices() -> void:
	choice_container.visible = true
	yes_button.grab_focus()

func _on_yes_pressed() -> void:
	choice_selected.emit(true)
	close_dialogue()

func _on_no_pressed() -> void:
	choice_selected.emit(false)
	close_dialogue()

func close_dialogue() -> void:
	set_process(false) # Stop processing frames when dialogue closes
	hide()
	queue_free()
	
