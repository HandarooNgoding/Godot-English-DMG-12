extends CanvasLayer

# --- Node References ---
@onready var background_texture_node: TextureRect = $BackgroundTexture # Reference to our new image node
@onready var wheel_interface: Control = $WheelInterface
@onready var letters_container: Node2D = $WheelInterface/LettersContainer
@onready var connection_line: Line2D = $WheelInterface/ConnectionLine
@onready var word_slots_container: HBoxContainer = $WheelInterface/WordSlotsContainer
@onready var round_label: Label = $WheelInterface/RoundLabel

# --- Configuration Constants ---
@export var radius: float = 120.0
@export var detection_radius: float = 40.0 

var words_per_round: int = 3 
var max_rounds: int = 3 
var master_glossary: Array[String] = []

# --- Gameplay State Parameters ---
var current_round: int = 1
var word_pool: Array[String] = [] 
var current_word: String = "" 
var selected_indices: Array[int] = [] 
var is_dragging: bool = false
var discovered_words: Array[String] = [] 
var used_words_this_run: Array[String] = [] 

var consecutive_failures: int = 0
var active_hints: Dictionary = {} 

func _ready() -> void:
	connection_line.clear_points()

# Updated initialization function that receives the texture resource from the NPC
func initialize_game(words: Array[String], background_img: Texture2D, per_round: int = 3, total_rounds: int = 3) -> void:
	master_glossary = words
	words_per_round = per_round
	max_rounds = total_rounds
	
	# NEW: Apply the NPC's custom level image texture dynamically to the background container
	if background_img and background_texture_node:
		background_texture_node.texture = background_img
	else:
		background_texture_node.texture = null # Fallback to a clean gray background color if empty
		
	current_round = 1
	used_words_this_run.clear()
	load_round(current_round)

func load_round(round_number: int) -> void:
	if round_label:
		round_label.text = "Round " + str(round_number) + " / " + str(max_rounds)
		
	discovered_words.clear()
	active_hints.clear() 
	consecutive_failures = 0 
	connection_line.clear_points()
	
	var available_words: Array[String] = []
	for word in master_glossary:
		var upper_word = word.strip_edges().to_upper()
		if not used_words_this_run.has(upper_word):
			available_words.append(upper_word)
			
	if available_words.size() < words_per_round:
		used_words_this_run.clear()
		available_words = master_glossary.duplicate()
		
	available_words.shuffle()
	
	word_pool.clear()
	for i in range(min(words_per_round, available_words.size())):
		var chosen_word = available_words[i]
		word_pool.append(chosen_word)
		used_words_this_run.append(chosen_word)
		
	current_word = extract_unique_letters(word_pool)
	generate_wheel(current_word)
	setup_word_slots()

func advance_round() -> void:
	current_round += 1
	if current_round <= max_rounds:
		load_round(current_round)
	else:
		trigger_victory()

func trigger_victory() -> void:
	var hub = get_parent()
	if hub and hub.has_method("return_to_overworld"):
		hub.return_to_overworld()
	queue_free()

func extract_unique_letters(pool: Array[String]) -> String:
	var unique_chars = {}
	for word in pool:
		for char in word:
			unique_chars[char] = true
			
	var letter_array = unique_chars.keys()
	letter_array.shuffle() 
	return "".join(letter_array)

func generate_wheel(word: String) -> void:
	for child in letters_container.get_children():
		child.queue_free()
		
	var letter_count = word.length()
	if letter_count == 0: return
	
	var angle_step = (2 * PI) / letter_count
	
	for i in range(letter_count):
		var angle = i * angle_step - (PI / 2)
		var letter_pos = Vector2(cos(angle), sin(angle)) * radius
		
		var letter_node = Node2D.new()
		letter_node.position = letter_pos
		letter_node.name = "Letter_" + str(i)
		letters_container.add_child(letter_node)
		
		var letter_scene = load("res://Scenes/LetterNode.tscn").instantiate()
		letter_node.add_child(letter_scene)
		
		var label = letter_scene.get_node("Label") as Label
		label.text = word[i]

func setup_word_slots() -> void:
	for child in word_slots_container.get_children():
		child.queue_free()
		word_slots_container.remove_child(child)
		
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
		update_mouse_line()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				check_letter_detection(letters_container.get_local_mouse_position())
			else:
				is_dragging = false
				finish_word_selection()
				
	elif event is InputEventMouseMotion and is_dragging:
		check_letter_detection(letters_container.get_local_mouse_position())

func check_letter_detection(local_mouse_pos: Vector2) -> void:
	for i in range(letters_container.get_child_count()):
		if selected_indices.has(i): continue
		var target_node = letters_container.get_child(i) as Node2D
		if local_mouse_pos.distance_to(target_node.position) < detection_radius:
			select_letter(i)
			break

func select_letter(index: int) -> void:
	selected_indices.append(index)
	var target_node = letters_container.get_child(index) as Node2D
	var exact_line_pos = connection_line.to_local(target_node.global_position)
	connection_line.add_point(exact_line_pos)

func update_mouse_line() -> void:
	if selected_indices.size() > 0:
		var line_localized_mouse = connection_line.to_local(letters_container.get_global_mouse_position())
		if connection_line.points.size() > selected_indices.size():
			connection_line.set_point_position(connection_line.points.size() - 1, line_localized_mouse)
		else:
			connection_line.add_point(line_localized_mouse)

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
	connection_line.clear_points()

	if round_cleared:
		advance_round()
		
