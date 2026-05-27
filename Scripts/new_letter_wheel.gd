extends CanvasLayer

# --- Node References ---
@onready var background_texture_node: TextureRect = $BackgroundTexture
@onready var wheel_interface: Control = $WheelInterface
@onready var letters_container: Node2D = $WheelInterface/LettersContainer
@onready var word_slots_container: HBoxContainer = $WheelInterface/WordSlotsContainer
@onready var round_label: Label = $WheelInterface/RoundLabel
@onready var exit_button: Button = $WheelInterface/ExitButton

# --- Configuration Constants ---
@export var radius: float = 120.0
@export var detection_radius: float = 40.0 

# Circle background rendering settings
@export var draw_wheel_background: bool = true
@export var wheel_background_radius: float = 160.0
@export var wheel_background_color: Color = Color(0, 0, 0, 0.4)

var max_rounds: int = 2 

# --- Gameplay State Parameters ---
var current_round: int = 1
var word_pool: Array[String] = [] 
var current_word: String = "" 
var selected_indices: Array[int] = [] 
var is_dragging: bool = false
var discovered_words: Array[String] = [] 

# Tracks which character launched this mini-game ("Mom", "Dad", "Sibling")
var current_character_id: String = ""

var consecutive_failures: int = 0
var active_hints: Dictionary = {} 

# Tracks active round-clear timers to prevent stacking
var active_clear_tween: Tween = null

# Math centers tracked natively relative to LettersContainer
var letter_positions: Array[Vector2] = []
var current_mouse_local: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_process(true)
	
	if exit_button and not exit_button.pressed.is_connected(close_minigame):
		exit_button.pressed.connect(close_minigame)

func initialize_game(_words: Array[String], background_img: Texture2D, _per_round: int = 3, _total_rounds: int = 3) -> void:
	if background_img and background_texture_node:
		background_texture_node.texture = background_img
	else:
		background_texture_node.texture = null
		
	current_round = 1
	load_round(current_round)

func load_round(round_number: int) -> void:
	var quest_data = QuestManager.quests.get(current_character_id)
	if not quest_data or not quest_data.has("stages") or quest_data["stages"].size() == 0:
		print("Error: Missing stage configurations for character reference: ", current_character_id)
		close_minigame()
		return
		
	var stage_index = round_number - 1
	max_rounds = quest_data["stages"].size()
	
	if round_label:
		round_label.text = "Stage " + str(round_number) + " / " + str(max_rounds)
		
	discovered_words.clear()
	active_hints.clear() 
	consecutive_failures = 0 
	selected_indices.clear()
	
	var current_stage_data = quest_data["stages"][stage_index]
	
	word_pool.clear()
	for word in current_stage_data["words"]:
		word_pool.append(word.to_upper())
		
	current_word = current_stage_data["letters"].to_upper()
	
	var hub = get_parent()
	if hub and "active_dialogue_instance" in hub and hub.active_dialogue_instance != null:
		var stage_text_prompt = current_stage_data.get("dialogue", "Solve the word puzzle!")
		if hub.active_dialogue_instance.has_method("show_puzzle_hint"):
			hub.active_dialogue_instance.show_puzzle_hint(stage_text_prompt)
	
	generate_wheel(current_word)
	setup_word_slots()
	
	if letters_container:
		letters_container.queue_redraw()

func advance_round() -> void:
	current_round += 1
	if current_round <= max_rounds:
		load_round(current_round)
	else:
		trigger_victory()

func trigger_victory() -> void:
	if current_character_id != "":
		QuestManager.complete_quest(current_character_id)
	close_minigame()

func generate_wheel(word: String) -> void:
	for child in letters_container.get_children():
		child.queue_free()
		
	letter_positions.clear()
	var letter_count = word.length()
	if letter_count == 0: return
	
	if letters_container.get_parent() is Control:
		letters_container.position = Vector2.ZERO
	
	var angle_step = (2 * PI) / letter_count
	
	if not letters_container.is_connected("draw", Callable(self, "_on_letters_container_draw")):
		letters_container.connect("draw", Callable(self, "_on_letters_container_draw"))
	
	for i in range(letter_count):
		var angle = i * angle_step - (PI / 2)
		var letter_pos = Vector2(cos(angle), sin(angle)) * radius
		letter_positions.append(letter_pos)
		
		var letter_node = Node2D.new()
		letter_node.position = letter_pos
		letter_node.name = "Letter_" + str(i)
		letters_container.add_child(letter_node)
		
		var letter_scene = load("res://Scenes/LetterNode.tscn").instantiate()
		letter_node.add_child(letter_scene)
		
		var label = letter_scene.get_node("Label") as Label
		if label:
			label.text = word[i]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.position = -label.size / 2.0

func setup_word_slots() -> void:
	for child in word_slots_container.get_children():
		child.queue_free()
		
	for word in word_pool:
		var slot_label = Label.new()
		slot_label.name = word
		slot_label.text = get_word_slot_display_text(word)
		slot_label.add_theme_font_size_override("font_size", 24)
		slot_label.custom_minimum_size = Vector2(40 * word.length(), 40)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		word_slots_container.add_child(slot_label)

func get_word_slot_display_text(word: String) -> String:
	if discovered_words.has(word):
		return word
		
	var display_text = ""
	var revealed_letters_count = active_hints.get(word, 0)
	
	for i in range(word.length()):
		if i < revealed_letters_count:
			display_text += word[i] + " "
		else:
			display_text += "_ "
	return display_text

func deploy_single_letter_hint() -> void:
	consecutive_failures = 0 
	for word in word_pool:
		if not discovered_words.has(word):
			var current_hints = active_hints.get(word, 0)
			if current_hints < word.length() - 1:
				active_hints[word] = current_hints + 1
				var ui_slot = word_slots_container.get_node_or_null(word) as Label
				if ui_slot:
					ui_slot.text = get_word_slot_display_text(word)
					ui_slot.add_theme_color_override("font_color", Color.YELLOW)
				break 

func _process(_delta: float) -> void:
	if is_dragging:
		current_mouse_local = letters_container.get_local_mouse_position()
		letters_container.queue_redraw()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_minigame()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if exit_button and exit_button.get_global_rect().has_point(event.global_position):
					return
				is_dragging = true
				check_letter_detection(letters_container.get_local_mouse_position())
			else:
				is_dragging = false
				finish_word_selection()
				
	elif event is InputEventMouseMotion and is_dragging:
		check_letter_detection(letters_container.get_local_mouse_position())

func check_letter_detection(local_mouse_pos: Vector2) -> void:
	for i in range(letter_positions.size()):
		if selected_indices.has(i): continue
		
		if local_mouse_pos.distance_to(letter_positions[i]) < detection_radius:
			selected_indices.append(i)
			letters_container.queue_redraw()
			break

func _on_letters_container_draw() -> void:
	if draw_wheel_background:
		letters_container.draw_circle(Vector2.ZERO, wheel_background_radius, wheel_background_color)

	if selected_indices.size() == 0:
		return
		
	for i in range(selected_indices.size() - 1):
		var start = letter_positions[selected_indices[i]]
		var end = letter_positions[selected_indices[i + 1]]
		letters_container.draw_line(start, end, Color.WHITE, 10.0, true)
		
	if is_dragging:
		var last_letter_center = letter_positions[selected_indices[-1]]
		letters_container.draw_line(last_letter_center, current_mouse_local, Color.WHITE, 10.0, true)

func get_selected_string() -> String:
	var result = ""
	for idx in selected_indices:
		result += current_word[idx]
	return result

func finish_word_selection() -> void:
	var final_word = get_selected_string()
	var round_cleared: bool = false
	
	if final_word.length() > 0:
		if word_pool.has(final_word):
			if not discovered_words.has(final_word):
				discovered_words.append(final_word)
				consecutive_failures = 0 
				
				var ui_slot = word_slots_container.get_node_or_null(final_word) as Label
				if ui_slot:
					ui_slot.text = final_word
					ui_slot.add_theme_color_override("font_color", Color.GREEN)
					
				if discovered_words.size() == word_pool.size():
					round_cleared = true
			else:
				print("Already found: ", final_word)
		else:
			consecutive_failures += 1
			if consecutive_failures >= 3:
				deploy_single_letter_hint()
			
	selected_indices.clear()
	letters_container.queue_redraw()

	if round_cleared:
		if active_clear_tween and active_clear_tween.is_valid():
			active_clear_tween.kill()
			
		active_clear_tween = create_tween()
		active_clear_tween.tween_callback(advance_round).set_delay(0.5)

func close_minigame() -> void:
	if active_clear_tween and active_clear_tween.is_valid():
		active_clear_tween.kill()
		
	var hub = get_parent()
	
	if hub and "active_dialogue_instance" in hub and hub.active_dialogue_instance != null:
		hub.active_dialogue_instance.close_dialogue()
		hub.active_dialogue_instance = null
		
	if hub and hub.has_method("return_to_overworld"):
		hub.return_to_overworld()
	queue_free()
