extends Node

signal quest_updated

# Master database mapped exactly to your inspector character identifiers
var quests: Dictionary = {
	"Mom": {
		"location": "Kitchen",
		"completed": false,
		"stages": [
			{
				"letters": "STEAM",
				"words": ["TEA", "MEAT", "EAT"],
				"dialogue": "Mom is boiling water to make a warm cup of _ _ _ . Can you help Mom wash the chicken and the _ _ _ _ ? The food is ready, let's sit and _ _ _ our dinner!"
			},
			{
				"letters": "WATER",
				"words": ["WET", "RAW", "WATER"],
				"dialogue": "Wash the vegetables in the sink until they are _ _ _ . Do not eat the food yet, it is still _ _ _ . Pour some _ _ _ _ _ into the pot to make soup."
			}
		]
	},
	"Sibling": {
		"location": "Room",
		"completed": false,
		"stages": [
			{
				"letters": "MOUSE",
				"words": ["USE", "SOME", "MOUSE"],
				"dialogue": "She turns on the computer, she wants to _ _ _ it to play games. Please wait, she needs _ _ _ _ time to load the game. She clicks on the computer screen using a gaming _ _ _ _ _ ."
			},
			{
				"letters": "CHAIR",
				"words": ["AIR", "HAIR", "CHAIR"],
				"dialogue": "The computer fan blows cool _ _ _ into the room. Kakak puts a gaming headset over her black _ _ _ _ . She sits comfortably on her big gaming _ _ _ _ _ ."
			}
		]
	},
	"Dad": {
		"location": "Garage",
		"completed": false,
		"stages": [
			{
				"letters": "CLEAR",
				"words": ["CAR", "EAR", "CLEAR"],
				"dialogue": "Dad is in the garage. He is washing his dirty _ _ _ . Listen to the car engine sound using your _ _ _ . We washed it! Now the windows are clean and _ _ _ _ _ ."
			},
			{
				"letters": "DRIVE",
				"words": ["RED", "RIDE", "DRIVE"],
				"dialogue": "The color of Dad's beautiful car is bright _ _ _ . The car is ready! Let's take a fun _ _ _ _ together. Dad will sit in the front and _ _ _ _ _ the car."
			}
		]
	}
}

func complete_quest(character_name: String) -> void:
	if quests.has(character_name):
		quests[character_name]["completed"] = true
		quest_updated.emit()
		check_for_endgame()

func is_quest_completed(character_name: String) -> bool:
	if quests.has(character_name):
		return quests[character_name]["completed"]
	return false

func check_for_endgame() -> void:
	var all_done = true
	for q_name in quests:
		# Exclude characters who don't have gameplay stages yet from blocking endgame
		if quests[q_name]["stages"].size() > 0 and not quests[q_name]["completed"]:
			all_done = false
			break
	if all_done:
		trigger_endgame()

func trigger_endgame() -> void:
	print("ALL QUESTS COMPLETE!")
	
	# --- THE FIX ---
	# Automatically change the scene to your new victory screen file!
	# (Double check that your file path matching "res://Scenes/EndScene.tscn" is spelled exactly right)
	get_tree().change_scene_to_file("res://Scenes/EndScene.tscn")
